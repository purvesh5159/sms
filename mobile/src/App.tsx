import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { AuthProvider, useAuth } from './context/AuthContext';
import AuthStack from './navigation/AuthStack';
import MainTabs from './navigation/MainTabs';

function Root() {
	const { token } = useAuth();
	return (
		<NavigationContainer>
			{token ? <MainTabs /> : <AuthStack />}
			<StatusBar style="auto" />
		</NavigationContainer>
	);
}

export default function App() {
	return (
		<AuthProvider>
			<Root />
		</AuthProvider>
	);
}