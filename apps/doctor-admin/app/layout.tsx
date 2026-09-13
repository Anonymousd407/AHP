import type { Metadata } from 'next';
import { Nav } from '@/components/Nav';
import './globals.css';

/*
 * One family across the scale; weight and size carry the hierarchy. Plex Mono
 * appears only on countdowns and lab values, where tabular figures stop the
 * number jittering as it ticks and keep a column of results aligned — both
 * cases where the digits are the content, not decoration.
 */
export const metadata: Metadata = {
  title: 'A-health — Daktari',
  description: 'Foleni ya kesi na usimamizi wa matibabu.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="sw">
      <body className="font-sans">
        <div className="flex min-h-screen">
          <Nav />
          <main className="min-w-0 flex-1">{children}</main>
        </div>
      </body>
    </html>
  );
}
