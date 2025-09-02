import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import * as SecureStore from 'expo-secure-store';
import { api } from '../lib/api';

type AuthContextType = {
	token: string | null;
	societyId: number | null;
	setSocietyId: (id: number | null) => void;
	login: (email: string, password?: string, societyId?: number) => Promise<boolean>;
	devLogin: (email: string, societyId?: number) => Promise<boolean>;
	logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextType>({
	token: null,
	societyId: null,
	setSocietyId: () => {},
	login: async () => false,
	devLogin: async () => false,
	logout: async () => {}
});

// Web-safe storage wrapper: SecureStore when available, else localStorage
const storage = {
	get: async (key: string) => {
		try {
			const available = typeof (SecureStore as any).isAvailableAsync === 'function'
				? await (SecureStore as any).isAvailableAsync()
				: false;
			if (available) return await SecureStore.getItemAsync(key);
			if (typeof localStorage !== 'undefined') return localStorage.getItem(key);
		} catch {}
		return null;
	},
	set: async (key: string, value: string) => {
		try {
			const available = typeof (SecureStore as any).isAvailableAsync === 'function'
				? await (SecureStore as any).isAvailableAsync()
				: false;
			if (available) return await SecureStore.setItemAsync(key, value);
			if (typeof localStorage !== 'undefined') localStorage.setItem(key, value);
		} catch {}
	},
	del: async (key: string) => {
		try {
			const available = typeof (SecureStore as any).isAvailableAsync === 'function'
				? await (SecureStore as any).isAvailableAsync()
				: false;
			if (available && typeof SecureStore.deleteItemAsync === 'function') {
				return await SecureStore.deleteItemAsync(key);
			}
			if (typeof localStorage !== 'undefined') localStorage.removeItem(key);
		} catch {}
	}
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
	const [token, setToken] = useState<string | null>(null);
	const [societyId, setSocietyIdState] = useState<number | null>(1);

	useEffect(() => {
		(async () => {
			const t = await storage.get('token');
			const sid = await storage.get('societyId');
			if (t) setToken(t);
			if (sid) setSocietyIdState(Number(sid));
		})();
	}, []);

	useEffect(() => {
		api.setToken(token);
		api.setSocietyId(societyId || undefined);
	}, [token, societyId]);

	const value = useMemo<AuthContextType>(() => ({
		token,
		societyId,
		setSocietyId: async (id) => {
			setSocietyIdState(id);
			if (id == null) await storage.del('societyId');
			else await storage.set('societyId', String(id));
		},
		login: async (email, password, sid) => {
			try {
				const res = await api.post('/auth/login', { email, password, societyId: sid });
				if (res?.token) {
					setToken(res.token);
					await storage.set('token', res.token);
					if (res.user?.societyId != null) {
						setSocietyIdState(res.user.societyId);
						await storage.set('societyId', String(res.user.societyId));
					}
					return true;
				}
			} catch {}
			return false;
		},
		devLogin: async (email, sid) => {
			try {
				const res = await api.post('/auth/dev-login', { email, societyId: sid });
				if (res?.token) {
					setToken(res.token);
					await storage.set('token', res.token);
					if (res.user?.societyId != null) {
						setSocietyIdState(Number(res.user.societyId));
						await storage.set('societyId', String(res.user.societyId));
					}
					return true;
				}
			} catch {}
			return false;
		},
		logout: async () => {
			setToken(null);
			await storage.del('token');
		}
	}), [token, societyId]);

	return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);