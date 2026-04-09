-- ============================================================
-- SaaS Scolaire Guinéen — Schéma Supabase Complet
-- ============================================================
-- Multi-tenant : chaque école a son espace isolé via school_id
-- RLS désactivé en MVP (comme spécifié dans le cahier des charges)
-- ============================================================

-- ========================
-- TYPES ÉNUMÉRÉS
-- ========================

CREATE TYPE user_role AS ENUM (
  'super_admin',
  'directeur',
  'proviseur',
  'maitre',
  'professeur',
  'eleve'
);

CREATE TYPE section_type AS ENUM (
  'primaire',
  'college',
  'lycee'
);

CREATE TYPE filiere_type AS ENUM (
  'generale',
  'sciences_sociales',      -- SS
  'sciences_mathematiques', -- SM
  'sciences_experimentales' -- SE
);

-- ========================
-- 1. ÉCOLES
-- ========================

CREATE TABLE schools (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  address     TEXT,
  city        TEXT DEFAULT 'Conakry',
  phone       TEXT,
  email       TEXT,
  logo_url    TEXT,
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ========================
-- 2. ANNÉES SCOLAIRES
-- ========================

CREATE TABLE school_years (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  label       TEXT NOT NULL,  -- ex: "2024-2025"
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  is_current  BOOLEAN DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now(),

  UNIQUE(school_id, label)
);

-- Un seul year courant par école
CREATE UNIQUE INDEX idx_one_current_year_per_school
  ON school_years (school_id) WHERE is_current = true;

-- ========================
-- 3. TRIMESTRES
-- ========================

CREATE TABLE trimesters (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_year_id  UUID NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
  number          SMALLINT NOT NULL CHECK (number BETWEEN 1 AND 3),
  start_date      DATE,
  end_date        DATE,
  composition_start DATE,  -- début des compositions
  composition_end   DATE,  -- fin des compositions
  is_active       BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE(school_year_id, number)
);

-- ========================
-- 4. PROFILS UTILISATEURS
-- ========================
-- Étend auth.users de Supabase

CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  school_id   UUID REFERENCES schools(id) ON DELETE SET NULL,  -- NULL pour super_admin
  role        user_role NOT NULL,
  first_name  TEXT NOT NULL,
  last_name   TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  section     section_type,  -- NULL pour super_admin et eleve (déduit de la classe)
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_profiles_school ON profiles(school_id);
CREATE INDEX idx_profiles_role ON profiles(role);

-- ========================
-- 5. MATIÈRES (référentiel)
-- ========================

CREATE TABLE subjects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID REFERENCES schools(id) ON DELETE CASCADE,  -- NULL = matière par défaut système
  name        TEXT NOT NULL,
  section     section_type NOT NULL,
  is_default  BOOLEAN DEFAULT false,  -- true = matière par défaut chargée auto
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_subjects_school ON subjects(school_id);
CREATE INDEX idx_subjects_section ON subjects(section);

-- ========================
-- 6. CLASSES
-- ========================

CREATE TABLE classes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  school_year_id  UUID NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,           -- ex: "CE1", "3ème A", "Terminale SS"
  level           TEXT,                    -- ex: "CE1", "6ème", "Terminale"
  section         section_type NOT NULL,
  filiere         filiere_type DEFAULT 'generale',  -- pertinent surtout pour le lycée
  maitre_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- uniquement primaire
  max_students    INT DEFAULT 60,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE(school_id, school_year_id, name)
);

CREATE INDEX idx_classes_school_year ON classes(school_id, school_year_id);
CREATE INDEX idx_classes_section ON classes(section);

-- ========================
-- 7. MATIÈRES PAR CLASSE (avec coefficients)
-- ========================

CREATE TABLE class_subjects (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id      UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id    UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- prof assigné (college/lycée)
  coefficient   NUMERIC(3,1) DEFAULT 1 CHECK (coefficient > 0),
  created_at    TIMESTAMPTZ DEFAULT now(),

  UNIQUE(class_id, subject_id)
);

CREATE INDEX idx_class_subjects_teacher ON class_subjects(teacher_id);

-- ========================
-- 8. IMPORT MATRICULES ÉLÈVES
-- ========================
-- Le Directeur/Proviseur importe les matricules avant que les élèves s'inscrivent

CREATE TABLE student_imports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  school_year_id  UUID NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
  class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  matricule       TEXT NOT NULL,
  first_name      TEXT NOT NULL,
  last_name       TEXT NOT NULL,
  is_claimed      BOOLEAN DEFAULT false,
  claimed_by      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE(school_id, matricule, school_year_id)
);

CREATE INDEX idx_student_imports_matricule ON student_imports(matricule);

-- ========================
-- 9. INSCRIPTIONS ÉLÈVES
-- ========================
-- Liaison élève ↔ classe pour une année scolaire

CREATE TABLE enrollments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  school_year_id  UUID NOT NULL REFERENCES school_years(id) ON DELETE CASCADE,
  matricule       TEXT NOT NULL,
  is_active       BOOLEAN DEFAULT true,
  enrolled_at     TIMESTAMPTZ DEFAULT now(),

  UNIQUE(student_id, school_year_id)
);

CREATE INDEX idx_enrollments_class ON enrollments(class_id);
CREATE INDEX idx_enrollments_matricule ON enrollments(matricule);

-- ========================
-- 10. NOTES MENSUELLES
-- ========================
-- 1 note écrite + 1 note orale par mois par matière par élève

CREATE TABLE monthly_grades (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  trimester_id    UUID NOT NULL REFERENCES trimesters(id) ON DELETE CASCADE,
  month_number    SMALLINT NOT NULL CHECK (month_number BETWEEN 1 AND 3),  -- mois 1, 2, 3 du trimestre
  note_ecrite     NUMERIC(4,2) CHECK (note_ecrite BETWEEN 0 AND 20),
  note_orale      NUMERIC(4,2) CHECK (note_orale BETWEEN 0 AND 20),
  created_by      UUID NOT NULL REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE(student_id, subject_id, trimester_id, month_number)
);

CREATE INDEX idx_monthly_grades_class ON monthly_grades(class_id);
CREATE INDEX idx_monthly_grades_trimester ON monthly_grades(trimester_id);

-- ========================
-- 11. NOTES DE COMPOSITION
-- ========================
-- 1 note de composition par trimestre par matière par élève

CREATE TABLE composition_grades (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  trimester_id    UUID NOT NULL REFERENCES trimesters(id) ON DELETE CASCADE,
  note            NUMERIC(4,2) CHECK (note BETWEEN 0 AND 20),
  created_by      UUID NOT NULL REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE(student_id, subject_id, trimester_id)
);

CREATE INDEX idx_composition_grades_class ON composition_grades(class_id);

-- ========================
-- 12. LIENS D'INVITATION (profs/maîtres)
-- ========================

CREATE TABLE invite_links (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  token       TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  role        user_role NOT NULL CHECK (role IN ('maitre', 'professeur')),
  section     section_type NOT NULL,
  class_id    UUID REFERENCES classes(id) ON DELETE SET NULL,  -- classe pré-assignée (optionnel)
  subject_id  UUID REFERENCES subjects(id) ON DELETE SET NULL, -- matière pré-assignée (optionnel)
  created_by  UUID NOT NULL REFERENCES profiles(id),
  expires_at  TIMESTAMPTZ DEFAULT (now() + interval '7 days'),
  is_used     BOOLEAN DEFAULT false,
  used_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  used_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_invite_links_token ON invite_links(token);

-- ========================
-- 13. EMPLOI DU TEMPS
-- ========================

CREATE TABLE schedule_slots (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id    UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id  UUID REFERENCES subjects(id) ON DELETE SET NULL,
  teacher_id  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 1 AND 6),  -- 1=Lundi, 6=Samedi
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  room        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),

  CHECK (end_time > start_time)
);

CREATE INDEX idx_schedule_class ON schedule_slots(class_id);
CREATE INDEX idx_schedule_teacher ON schedule_slots(teacher_id);

-- ========================
-- 14. NOTIFICATIONS
-- ========================

CREATE TABLE notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id     UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  recipient_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type          TEXT NOT NULL,  -- 'saisie_notes', 'bulletin_disponible', 'rappel_72h', etc.
  title         TEXT NOT NULL,
  message       TEXT,
  is_read       BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, is_read);

-- ========================
-- 15. SUIVI DE SAISIE DES NOTES (Garantie 72h)
-- ========================

CREATE TABLE grade_submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id      UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  trimester_id    UUID NOT NULL REFERENCES trimesters(id) ON DELETE CASCADE,
  type            TEXT NOT NULL CHECK (type IN ('monthly', 'composition')),
  month_number    SMALLINT CHECK (month_number BETWEEN 1 AND 3),  -- NULL si type = composition
  total_students  INT DEFAULT 0,
  graded_students INT DEFAULT 0,
  is_complete     BOOLEAN DEFAULT false,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE(teacher_id, class_id, subject_id, trimester_id, type, month_number)
);

-- ========================
-- 16. FILIÈRES — MATIÈRES PRINCIPALES (ex-aequo lycée)
-- ========================

CREATE TABLE filiere_settings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  filiere               filiere_type NOT NULL,
  main_subject_id       UUID REFERENCES subjects(id) ON DELETE SET NULL,  -- matière de départage
  created_at            TIMESTAMPTZ DEFAULT now(),

  UNIQUE(school_id, filiere)
);

-- ============================================================
-- VUES CALCULÉES
-- ============================================================

-- Vue : Moyenne du Cours (Mc) par élève par matière par trimestre
-- Mc = somme des 6 notes (écrite + orale × 3 mois) ÷ 6

CREATE OR REPLACE VIEW v_moyenne_cours AS
SELECT
  mg.student_id,
  mg.class_id,
  mg.subject_id,
  mg.trimester_id,
  COUNT(*) AS nb_notes_saisies,
  ROUND(
    (COALESCE(SUM(mg.note_ecrite), 0) + COALESCE(SUM(mg.note_orale), 0)) /
    NULLIF(COUNT(NULLIF(mg.note_ecrite, NULL)) + COUNT(NULLIF(mg.note_orale, NULL)), 0),
    2
  ) AS mc
FROM monthly_grades mg
GROUP BY mg.student_id, mg.class_id, mg.subject_id, mg.trimester_id;

-- Vue : MG par matière = (Mc + Mcompo) ÷ 2

CREATE OR REPLACE VIEW v_mg_matiere AS
SELECT
  vmc.student_id,
  vmc.class_id,
  vmc.subject_id,
  vmc.trimester_id,
  vmc.mc,
  cg.note AS mcompo,
  CASE
    WHEN vmc.mc IS NOT NULL AND cg.note IS NOT NULL
    THEN ROUND((vmc.mc + cg.note) / 2, 2)
    ELSE NULL
  END AS mg
FROM v_moyenne_cours vmc
LEFT JOIN composition_grades cg
  ON cg.student_id = vmc.student_id
  AND cg.subject_id = vmc.subject_id
  AND cg.trimester_id = vmc.trimester_id;

-- Vue : Moyenne Générale par élève par trimestre
-- MG = Somme(MG_matière × coefficient) ÷ Somme(coefficients)

CREATE OR REPLACE VIEW v_moyenne_generale AS
SELECT
  vm.student_id,
  vm.class_id,
  vm.trimester_id,
  ROUND(
    SUM(vm.mg * cs.coefficient) / NULLIF(SUM(cs.coefficient), 0),
    2
  ) AS moyenne_generale,
  SUM(cs.coefficient) AS total_coefficients,
  COUNT(vm.mg) AS nb_matieres_notees,
  -- Mention
  CASE
    WHEN ROUND(SUM(vm.mg * cs.coefficient) / NULLIF(SUM(cs.coefficient), 0), 2) >= 16 THEN 'Très Bien'
    WHEN ROUND(SUM(vm.mg * cs.coefficient) / NULLIF(SUM(cs.coefficient), 0), 2) >= 14 THEN 'Bien'
    WHEN ROUND(SUM(vm.mg * cs.coefficient) / NULLIF(SUM(cs.coefficient), 0), 2) >= 12 THEN 'Assez Bien'
    WHEN ROUND(SUM(vm.mg * cs.coefficient) / NULLIF(SUM(cs.coefficient), 0), 2) >= 10 THEN 'Passable'
    ELSE NULL
  END AS mention,
  -- Verdict (9.90+ arrondi à 10 = Admis)
  CASE
    WHEN ROUND(SUM(vm.mg * cs.coefficient) / NULLIF(SUM(cs.coefficient), 0), 2) >= 9.90 THEN 'Admis'
    ELSE 'Non admis'
  END AS verdict
FROM v_mg_matiere vm
JOIN class_subjects cs
  ON cs.class_id = vm.class_id
  AND cs.subject_id = vm.subject_id
WHERE vm.mg IS NOT NULL
GROUP BY vm.student_id, vm.class_id, vm.trimester_id;

-- ============================================================
-- FONCTIONS
-- ============================================================

-- Fonction : classement des élèves dans une classe pour un trimestre
CREATE OR REPLACE FUNCTION get_classement(
  p_class_id UUID,
  p_trimester_id UUID
)
RETURNS TABLE (
  student_id UUID,
  moyenne_generale NUMERIC,
  rang INT,
  total_eleves INT
)
LANGUAGE sql STABLE AS $$
  WITH ranked AS (
    SELECT
      vg.student_id,
      vg.moyenne_generale,
      RANK() OVER (ORDER BY vg.moyenne_generale DESC) AS rang,
      COUNT(*) OVER () AS total_eleves
    FROM v_moyenne_generale vg
    WHERE vg.class_id = p_class_id
      AND vg.trimester_id = p_trimester_id
  )
  SELECT * FROM ranked;
$$;

-- Fonction : progression de saisie des notes pour le tableau de bord Directeur/Proviseur
CREATE OR REPLACE FUNCTION get_grade_progress(
  p_school_id UUID,
  p_trimester_id UUID,
  p_section section_type DEFAULT NULL
)
RETURNS TABLE (
  total_teachers INT,
  teachers_completed INT,
  completion_percentage NUMERIC
)
LANGUAGE sql STABLE AS $$
  WITH teacher_status AS (
    SELECT
      cs.teacher_id,
      BOOL_AND(COALESCE(gs.is_complete, false)) AS all_complete
    FROM class_subjects cs
    JOIN classes c ON c.id = cs.class_id
    LEFT JOIN grade_submissions gs
      ON gs.teacher_id = cs.teacher_id
      AND gs.class_id = cs.class_id
      AND gs.subject_id = cs.subject_id
      AND gs.trimester_id = p_trimester_id
      AND gs.type = 'composition'
    WHERE c.school_id = p_school_id
      AND (p_section IS NULL OR c.section = p_section)
      AND cs.teacher_id IS NOT NULL
    GROUP BY cs.teacher_id
  )
  SELECT
    COUNT(*)::INT AS total_teachers,
    COUNT(*) FILTER (WHERE all_complete)::INT AS teachers_completed,
    ROUND(COUNT(*) FILTER (WHERE all_complete)::NUMERIC / NULLIF(COUNT(*), 0) * 100, 1) AS completion_percentage
  FROM teacher_status;
$$;

-- ============================================================
-- MATIÈRES PAR DÉFAUT (seed)
-- ============================================================

-- Primaire
INSERT INTO subjects (name, section, is_default) VALUES
  ('Lecture', 'primaire', true),
  ('Écriture', 'primaire', true),
  ('Calcul', 'primaire', true),
  ('Sciences d''Éveil', 'primaire', true),
  ('Histoire-Géographie', 'primaire', true),
  ('Éducation Civique', 'primaire', true);

-- Collège
INSERT INTO subjects (name, section, is_default) VALUES
  ('Français', 'college', true),
  ('Mathématiques', 'college', true),
  ('Histoire-Géographie', 'college', true),
  ('Sciences Physiques', 'college', true),
  ('Biologie', 'college', true),
  ('Anglais', 'college', true),
  ('Éducation Civique', 'college', true);

-- Lycée
INSERT INTO subjects (name, section, is_default) VALUES
  ('Français', 'lycee', true),
  ('Mathématiques', 'lycee', true),
  ('Histoire-Géographie', 'lycee', true),
  ('Sciences Physiques', 'lycee', true),
  ('Biologie', 'lycee', true),
  ('Anglais', 'lycee', true),
  ('Philosophie', 'lycee', true),
  ('Économie', 'lycee', true);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Trigger : mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_schools_updated_at
  BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_classes_updated_at
  BEFORE UPDATE ON classes FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_monthly_grades_updated_at
  BEFORE UPDATE ON monthly_grades FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_composition_grades_updated_at
  BEFORE UPDATE ON composition_grades FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_grade_submissions_updated_at
  BEFORE UPDATE ON grade_submissions FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger : créer automatiquement le profil après inscription Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, first_name, last_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'eleve')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
