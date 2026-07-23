"use client";

import { createContext, useContext, useState, useEffect, type ReactNode } from "react";
import { login as apiLogin, type LoginResponse } from "./api";

interface AuthContextType {
  token: string | null;
  role: string | null;
  fullName: string | null;
  isAuthenticated: boolean;
  login: (phoneNumber: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  const [role, setRole] = useState<string | null>(null);
  const [fullName, setFullName] = useState<string | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem("admin_auth");
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        setToken(parsed.token);
        setRole(parsed.role);
        setFullName(parsed.fullName);
      } catch {
        localStorage.removeItem("admin_auth");
      }
    }
  }, []);

  const login = async (phoneNumber: string, password: string) => {
    const res: LoginResponse = await apiLogin(phoneNumber, password);
    setToken(res.token);
    setRole(res.role);
    setFullName(res.fullName);
    localStorage.setItem("admin_auth", JSON.stringify(res));
  };

  const logout = () => {
    setToken(null);
    setRole(null);
    setFullName(null);
    localStorage.removeItem("admin_auth");
  };

  return (
    <AuthContext.Provider
      value={{
        token,
        role,
        fullName,
        isAuthenticated: !!token,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
