-- Seed data for development and testing

-- Create default tenant
INSERT INTO tenants (id, name, slug, plan, status)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Demo Tenant', 'demo', 'enterprise', 'active')
ON CONFLICT DO NOTHING;

-- Create default system roles
INSERT INTO roles (tenant_id, name, description, permissions, is_system)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Admin', 'Full system access',
     '["*"]'::jsonb, true),
    ('00000000-0000-0000-0000-000000000001', 'Developer', 'Deploy and manage deployments',
     '["orgs:read", "orgs:write", "deployments:read", "deployments:write", "pipelines:read", "pipelines:write"]'::jsonb, true),
    ('00000000-0000-0000-0000-000000000001', 'Viewer', 'Read-only access',
     '["orgs:read", "deployments:read", "pipelines:read"]'::jsonb, true)
ON CONFLICT DO NOTHING;

-- Create demo user
INSERT INTO users (id, tenant_id, email, name, provider, status)
VALUES
    ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001',
     'admin@demo.com', 'Demo Admin', 'local', 'active')
ON CONFLICT DO NOTHING;

-- Assign admin role to demo user
INSERT INTO user_roles (user_id, role_id)
SELECT '00000000-0000-0000-0000-000000000002', id
FROM roles
WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Admin'
ON CONFLICT DO NOTHING;
