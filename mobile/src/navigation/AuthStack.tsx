import React, { useState } from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { View, Text, TextInput, Button, StyleSheet } from 'react-native';
import { useAuth } from '../context/AuthContext';

const Stack = createNativeStackNavigator();

function LoginScreen() {
	const { login, devLogin, societyId, setSocietyId } = useAuth();
	const [email, setEmail] = useState('admin@society.local');
	const [password, setPassword] = useState('');
	const [sid, setSid] = useState(String(societyId || 1));
	const [loading, setLoading] = useState(false);

	async function onLogin() {
		setLoading(true);
		const ok = password ? await login(email, password, Number(sid)) : await devLogin(email, Number(sid));
		setLoading(false);
		if (!ok) alert('Login failed');
	}

	return (
		<View style={styles.container}>
			<Text style={styles.title}>Sign in</Text>
			<TextInput value={email} onChangeText={setEmail} placeholder="Email" autoCapitalize='none' style={styles.input} />
			<TextInput value={password} onChangeText={setPassword} placeholder="Password (leave empty for dev-login)" secureTextEntry style={styles.input} />
			<TextInput value={sid} onChangeText={setSid} placeholder="Society ID" keyboardType='numeric' style={styles.input} />
			<Button title={loading ? '...' : 'Continue'} onPress={onLogin} />
		</View>
	);
}

export default function AuthStack() {
	return (
		<Stack.Navigator>
			<Stack.Screen name="Login" component={LoginScreen} />
		</Stack.Navigator>
	);
}

const styles = StyleSheet.create({
	container: { flex: 1, justifyContent: 'center', padding: 16, gap: 12 },
	title: { fontSize: 24, fontWeight: '600', marginBottom: 8, textAlign: 'center' },
	input: { borderWidth: 1, borderColor: '#ccc', borderRadius: 8, padding: 12 }
});