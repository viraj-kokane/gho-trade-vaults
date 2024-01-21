'use client';
import { WagmiConfig, createConfig } from "wagmi";
import { ConnectKitProvider, ConnectKitButton, getDefaultConfig } from "connectkit";

const config = createConfig(
  getDefaultConfig({
    alchemyId: process.env.INFURA_ID, 
    walletConnectProjectId: process.env.NEXT_WALLETCONNECT_PROJECT_ID || "",

    appName: "GHO Trade Vaults",
    appDescription: "GHO Trade Vaults introduces an innovative approach to DeFi, allowing users to trade digital assets at predetermined prices. This platform is aimed at providing a secure and stable trading experience, free from the fluctuations and unpredictability of traditional market pricing.",
    appUrl: "https://family.co", 
    appIcon: "https://family.co/logo.png", 
  }),
);

export const ConnectkitProvider = ({ children }) => {
  return (
    <WagmiConfig config={config}>
      <ConnectKitProvider theme="retro">
        { children }
        <ConnectKitButton />
      </ConnectKitProvider>
    </WagmiConfig>
  );
};