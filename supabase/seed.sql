-- ============================================================
-- SEED DATA — Démo École Fictive
-- ============================================================
-- Données réalistes pour convaincre un proviseur en démo live
-- École : Lycée Classique de Conakry
-- ============================================================

-- 1. École fictive
INSERT INTO schools (id, name, address, city, phone, email) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Lycée Classique de Conakry', 'Quartier Almamya, Commune de Kaloum', 'Conakry', '+224 621 00 00 01', 'contact@lcc.edu.gn');

-- 2. Année scolaire
INSERT INTO school_years (id, school_id, label, start_date, end_date, is_current) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', '2025-2026', '2025-10-01', '2026-06-30', true);

-- 3. Trimestres
INSERT INTO trimesters (id, school_year_id, number, start_date, end_date, composition_start, composition_end, is_active) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 1, '2025-10-01', '2025-12-31', '2025-12-15', '2025-12-22', true),
  ('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 2, '2026-01-05', '2026-03-31', '2026-03-16', '2026-03-23', false),
  ('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 3, '2026-04-07', '2026-06-30', '2026-06-15', '2026-06-22', false);

-- 4. Classes

-- Primaire
INSERT INTO classes (id, school_id, school_year_id, name, level, section, filiere) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'CE1', 'CE1', 'primaire', 'generale'),
  ('d0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'CE2', 'CE2', 'primaire', 'generale'),
  ('d0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'CM1', 'CM1', 'primaire', 'generale'),
  ('d0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'CM2', 'CM2', 'primaire', 'generale');

-- Collège
INSERT INTO classes (id, school_id, school_year_id, name, level, section, filiere) VALUES
  ('d0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '6ème A', '6ème', 'college', 'generale'),
  ('d0000000-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '5ème A', '5ème', 'college', 'generale'),
  ('d0000000-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '4ème A', '4ème', 'college', 'generale'),
  ('d0000000-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '3ème A', '3ème', 'college', 'generale');

-- Lycée
INSERT INTO classes (id, school_id, school_year_id, name, level, section, filiere) VALUES
  ('d0000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '2nde A', '2nde', 'lycee', 'generale'),
  ('d0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', '1ère SS', '1ère', 'lycee', 'sciences_sociales'),
  ('d0000000-0000-0000-0000-000000000022', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Terminale SM', 'Terminale', 'lycee', 'sciences_mathematiques'),
  ('d0000000-0000-0000-0000-000000000023', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Terminale SE', 'Terminale', 'lycee', 'sciences_experimentales');

-- 5. Matières par classe (avec coefficients réalistes)

-- CE1 — Primaire (coeff par défaut = 1)
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000001', id, 1
FROM subjects WHERE is_default = true AND section = 'primaire';

-- CE2 — Primaire
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000002', id, 1
FROM subjects WHERE is_default = true AND section = 'primaire';

-- CM1 — Primaire
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000003', id, 1
FROM subjects WHERE is_default = true AND section = 'primaire';

-- CM2 — Primaire
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000004', id, 1
FROM subjects WHERE is_default = true AND section = 'primaire';

-- 6ème A — Collège
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000010', id,
  CASE name
    WHEN 'Français' THEN 3
    WHEN 'Mathématiques' THEN 3
    WHEN 'Histoire-Géographie' THEN 2
    WHEN 'Sciences Physiques' THEN 2
    WHEN 'Biologie' THEN 2
    WHEN 'Anglais' THEN 2
    WHEN 'Éducation Civique' THEN 1
    ELSE 1
  END
FROM subjects WHERE is_default = true AND section = 'college';

-- Terminale SM — Lycée (coefficients filière scientifique maths)
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000022', id,
  CASE name
    WHEN 'Mathématiques' THEN 5
    WHEN 'Sciences Physiques' THEN 4
    WHEN 'Biologie' THEN 3
    WHEN 'Français' THEN 2
    WHEN 'Anglais' THEN 2
    WHEN 'Philosophie' THEN 2
    WHEN 'Histoire-Géographie' THEN 2
    WHEN 'Économie' THEN 1
    ELSE 1
  END
FROM subjects WHERE is_default = true AND section = 'lycee';

-- Terminale SE — Lycée (coefficients filière sciences expérimentales)
INSERT INTO class_subjects (class_id, subject_id, coefficient)
SELECT 'd0000000-0000-0000-0000-000000000023', id,
  CASE name
    WHEN 'Biologie' THEN 5
    WHEN 'Sciences Physiques' THEN 4
    WHEN 'Mathématiques' THEN 3
    WHEN 'Français' THEN 2
    WHEN 'Anglais' THEN 2
    WHEN 'Philosophie' THEN 2
    WHEN 'Histoire-Géographie' THEN 2
    WHEN 'Économie' THEN 1
    ELSE 1
  END
FROM subjects WHERE is_default = true AND section = 'lycee';

-- 6. Filière settings (matières de départage pour ex-aequo)
INSERT INTO filiere_settings (school_id, filiere, main_subject_id)
SELECT 'a0000000-0000-0000-0000-000000000001', 'sciences_sociales', id
FROM subjects WHERE name = 'Français' AND section = 'lycee' AND is_default = true LIMIT 1;

INSERT INTO filiere_settings (school_id, filiere, main_subject_id)
SELECT 'a0000000-0000-0000-0000-000000000001', 'sciences_mathematiques', id
FROM subjects WHERE name = 'Mathématiques' AND section = 'lycee' AND is_default = true LIMIT 1;

INSERT INTO filiere_settings (school_id, filiere, main_subject_id)
SELECT 'a0000000-0000-0000-0000-000000000001', 'sciences_experimentales', id
FROM subjects WHERE name = 'Biologie' AND section = 'lycee' AND is_default = true LIMIT 1;

-- 7. Matricules élèves pré-importés (Terminale SM — 15 élèves fictifs)
INSERT INTO student_imports (school_id, school_year_id, class_id, matricule, first_name, last_name) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-001', 'Mamadou', 'Diallo'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-002', 'Fatoumata', 'Bah'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-003', 'Ibrahima', 'Camara'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-004', 'Aissatou', 'Barry'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-005', 'Ousmane', 'Sylla'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-006', 'Mariama', 'Condé'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-007', 'Alpha', 'Touré'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-008', 'Kadiatou', 'Keita'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-009', 'Mohamed', 'Soumah'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-010', 'Fanta', 'Bangoura'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-011', 'Thierno', 'Balde'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-012', 'Aminata', 'Sow'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-013', 'Abdoulaye', 'Diakité'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-014', 'Hawa', 'Cissé'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000022', 'LCC-2526-015', 'Sékou', 'Traoré');

-- Matricules CE1 — Primaire (10 élèves)
INSERT INTO student_imports (school_id, school_year_id, class_id, matricule, first_name, last_name) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P01', 'Moussa', 'Camara'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P02', 'Djénabou', 'Diallo'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P03', 'Lansana', 'Kouyaté'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P04', 'Nènè', 'Bah'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P05', 'Mamady', 'Touré'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P06', 'Saran', 'Barry'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P07', 'Fodé', 'Keita'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P08', 'Oumou', 'Sylla'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P09', 'Bangaly', 'Condé'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'LCC-2526-P10', 'Mariame', 'Soumah');

-- ============================================================
-- NOTE : Les profils (profiles) sont créés via Supabase Auth
-- en production. Pour la démo, il faudra créer les users via
-- le dashboard Supabase ou via l'API Auth :
--
-- Comptes à créer pour la démo :
-- 1. super@lcc.edu.gn     (SuperAdmin)
-- 2. directeur@lcc.edu.gn (Directeur - primaire)
-- 3. proviseur@lcc.edu.gn (Proviseur - collège/lycée)
-- 4. maitre.ce1@lcc.edu.gn (Maître CE1)
-- 5. prof.maths@lcc.edu.gn (Prof Maths - Terminale SM)
-- 6. prof.physique@lcc.edu.gn (Prof Physique - Terminale SM)
-- 7. eleve.diallo@lcc.edu.gn (Mamadou Diallo - LCC-2526-001)
-- ============================================================
