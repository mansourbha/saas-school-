import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  GraduationCap,
  BookOpen,
  CreditCard,
  Settings,
  LogOut,
} from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Tableau de bord' },
  { to: '/students', icon: Users, label: 'Eleves' },
  { to: '/teachers', icon: GraduationCap, label: 'Enseignants' },
  { to: '/classes', icon: BookOpen, label: 'Classes' },
  { to: '/payments', icon: CreditCard, label: 'Paiements' },
  { to: '/settings', icon: Settings, label: 'Parametres' },
]

export default function Sidebar() {
  const { signOut } = useAuth()

  return (
    <aside className="w-64 bg-white border-r border-gray-200 min-h-screen flex flex-col">
      <div className="p-6 border-b border-gray-200">
        <h1 className="text-xl font-bold text-primary">SaaS Scolaire</h1>
        <p className="text-sm text-gray-500 mt-1">Gestion scolaire</p>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary text-white'
                  : 'text-gray-600 hover:bg-gray-100'
              }`
            }
          >
            <Icon size={20} />
            {label}
          </NavLink>
        ))}
      </nav>

      <div className="p-4 border-t border-gray-200">
        <button
          onClick={signOut}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-100 w-full transition-colors"
        >
          <LogOut size={20} />
          Deconnexion
        </button>
      </div>
    </aside>
  )
}
