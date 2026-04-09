import { Users, GraduationCap, BookOpen, CreditCard } from 'lucide-react'

const stats = [
  { label: 'Eleves', value: '—', icon: Users, color: 'bg-blue-500' },
  { label: 'Enseignants', value: '—', icon: GraduationCap, color: 'bg-green-500' },
  { label: 'Classes', value: '—', icon: BookOpen, color: 'bg-purple-500' },
  { label: 'Paiements', value: '—', icon: CreditCard, color: 'bg-amber-500' },
]

export default function DashboardPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Tableau de bord</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map(({ label, value, icon: Icon, color }) => (
          <div
            key={label}
            className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{label}</p>
                <p className="text-3xl font-bold text-gray-900 mt-1">{value}</p>
              </div>
              <div className={`${color} p-3 rounded-lg`}>
                <Icon size={24} className="text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
