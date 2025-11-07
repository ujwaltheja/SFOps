import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme, CssBaseline } from '@mui/material';
import { ApolloClient, InMemoryCache, ApolloProvider } from '@apollo/client';
import { Layout } from './components/Layout';
import { Dashboard } from './pages/Dashboard';
import { Orgs } from './pages/Orgs';
import { Deployments } from './pages/Deployments';
import { DeploymentDetail } from './pages/DeploymentDetail';
import { Pipelines } from './pages/Pipelines';
import { Compare } from './pages/Compare';
import { Login } from './pages/Login';
import { useAuthStore } from './stores/authStore';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

const client = new ApolloClient({
  uri: import.meta.env.VITE_GRAPHQL_URL || 'http://localhost:3000/graphql',
  cache: new InMemoryCache(),
});

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore(state => !!state.token);
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" />;
}

export function App() {
  return (
    <ApolloProvider client={client}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <Layout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="orgs" element={<Orgs />} />
              <Route path="deployments" element={<Deployments />} />
              <Route path="deployments/:id" element={<DeploymentDetail />} />
              <Route path="pipelines" element={<Pipelines />} />
              <Route path="compare" element={<Compare />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ThemeProvider>
    </ApolloProvider>
  );
}
