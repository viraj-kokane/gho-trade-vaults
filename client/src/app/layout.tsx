import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ConnectkitProvider } from "./connectkit-provider";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "GHO Trade Vaults",
  description: "GHO Trade Vaults introduces an innovative approach to DeFi, allowing users to trade digital assets at predetermined prices. This platform is aimed at providing a secure and stable trading experience, free from the fluctuations and unpredictability of traditional market pricing.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <ConnectkitProvider>
         {children}
        </ConnectkitProvider>
      </body>
    </html>
  );
}
