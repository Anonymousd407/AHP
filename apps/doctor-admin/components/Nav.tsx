'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { signOut } from 'next-auth/react';
import {
  Inbox, CalendarDays, FlaskConical, HeartPulse, Users2, MessagesSquare,
  Sparkles, BookOpen, Pill, ShieldCheck, Settings, LogOut, Stethoscope,
} from 'lucide-react';

/**
 * Grouped by when a clinician reaches for them, not alphabetically. The queue
 * is first because that is where a shift starts; reference material is last
 * because it is looked up, not worked through.
 */
const GROUPS = [
  {
    label: 'Kazi ya leo',
    items: [
      { icon: Inbox, label: 'Foleni', href: '/queue' },
      { icon: CalendarDays, label: 'Miadi', href: '/appointments' },
      { icon: Stethoscope, label: 'Ratiba yangu', href: '/slots' },
    ],
  },
  {
    label: 'Wagonjwa',
    items: [
      { icon: FlaskConical, label: 'Vipimo', href: '/diagnostics' },
      { icon: HeartPulse, label: 'Ufuatiliaji', href: '/follow-up' },
      { icon: Users2, label: 'Familia', href: '/families' },
    ],
  },
  {
    label: 'Wataalamu',
    items: [
      { icon: MessagesSquare, label: 'Jamii', href: '/network' },
      { icon: ShieldCheck, label: 'Maoni ya pili', href: '/second-opinions' },
    ],
  },
  {
    label: 'Rejea',
    items: [
      { icon: Sparkles, label: 'Msaidizi', href: '/assistant' },
      { icon: Pill, label: 'Dawa', href: '/pharmacy' },
      { icon: BookOpen, label: 'Elimu', href: '/education' },
      { icon: Settings, label: 'Mipangilio', href: '/settings' },
    ],
  },
];

// Reached before signing in. Showing the signed-in navigation there tells
// someone with no session exactly what the app contains.
const HIDE_ON = ['/login'];

export function Nav() {
  const pathname = usePathname() ?? '';
  if (HIDE_ON.some((r) => pathname.startsWith(r))) return null;

  return (
    <aside className="w-60 shrink-0 border-r border-line bg-white">
      <div className="sticky top-0 flex h-screen flex-col overflow-y-auto p-5">
        <Link href="/queue" className="text-lg font-semibold tracking-tight text-petrol">
          A-health
        </Link>

        <nav className="mt-6 flex-1">
          {GROUPS.map((group) => (
            <div key={group.label} className="mb-6">
              <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-ink-soft">
                {group.label}
              </p>
              {group.items.map((item) => {
                const active = pathname.startsWith(item.href);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`flex min-h-10 items-center gap-2.5 px-2 text-[0.95rem] ${
                      active ? 'font-medium text-petrol' : 'text-ink-soft hover:text-ink'
                    }`}
                  >
                    <item.icon size={17} aria-hidden />
                    {item.label}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        <button
          onClick={() => signOut({ callbackUrl: '/login' })}
          className="flex min-h-10 items-center gap-2.5 px-2 text-[0.95rem] text-ink-soft hover:text-ink"
        >
          <LogOut size={17} aria-hidden />
          Toka
        </button>
      </div>
    </aside>
  );
}
