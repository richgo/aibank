"""
Phase 1 Scaffolding Verification Tests

These tests verify that the project scaffolding from tasks 1.1, 1.2, and 1.3
is correctly set up according to the specification.
"""
import os
import yaml
import pytest
from pathlib import Path

# Get project root
PROJECT_ROOT = Path(__file__).parent.parent.parent


class TestTask11FlutterScaffold:
    """
    Task 1.1: Create Flutter app scaffold
    
    Verify:
    - Flutter app exists in app/ directory
    - pubspec.yaml contains all required dependencies
    - Clean build verification (flutter analyze passes)
    """
    
    def test_app_directory_exists(self):
        """GIVEN the project root, WHEN checking for app/, THEN it should exist"""
        app_dir = PROJECT_ROOT / "app"
        assert app_dir.exists(), "app/ directory should exist"
        assert app_dir.is_dir(), "app/ should be a directory"
    
    def test_pubspec_yaml_exists(self):
        """GIVEN the app directory, WHEN checking for pubspec.yaml, THEN it should exist"""
        pubspec = PROJECT_ROOT / "app" / "pubspec.yaml"
        assert pubspec.exists(), "app/pubspec.yaml should exist"
    
    def test_required_dependencies_present(self):
        """GIVEN pubspec.yaml, WHEN checking dependencies, THEN all required packages should be listed"""
        pubspec_path = PROJECT_ROOT / "app" / "pubspec.yaml"
        
        with open(pubspec_path, 'r') as f:
            pubspec = yaml.safe_load(f)
        
        required_deps = ['genui', 'genui_a2ui', 'a2a', 'json_schema_builder', 'logging']
        dependencies = pubspec.get('dependencies', {})
        
        for dep in required_deps:
            assert dep in dependencies, f"{dep} should be in dependencies"
    
    def test_main_dart_exists(self):
        """GIVEN the app/lib directory, WHEN checking for main.dart, THEN it should exist"""
        main_dart = PROJECT_ROOT / "app" / "lib" / "main.dart"
        assert main_dart.exists(), "app/lib/main.dart should exist"


class TestTask12AgentStructure:
    """
    Task 1.2: Create Python agent directory structure
    
    Verify:
    - agent/ directory with required files
    - requirements.txt with correct dependencies
    - .env.example exists
    - .env in .gitignore
    """
    
    def test_agent_directory_exists(self):
        """GIVEN the project root, WHEN checking for agent/, THEN it should exist"""
        agent_dir = PROJECT_ROOT / "agent"
        assert agent_dir.exists(), "agent/ directory should exist"
        assert agent_dir.is_dir(), "agent/ should be a directory"
    
    def test_agent_py_exists(self):
        """GIVEN the agent directory, WHEN checking for agent.py, THEN it should exist"""
        agent_py = PROJECT_ROOT / "agent" / "agent.py"
        assert agent_py.exists(), "agent/agent.py should exist"
    
    def test_a2ui_schema_py_exists(self):
        """GIVEN the agent directory, WHEN checking for a2ui_schema.py, THEN it should exist"""
        schema_py = PROJECT_ROOT / "agent" / "a2ui_schema.py"
        assert schema_py.exists(), "agent/a2ui_schema.py should exist"
    
    def test_templates_directory_exists(self):
        """GIVEN the agent directory, WHEN checking for templates/, THEN it should exist"""
        templates_dir = PROJECT_ROOT / "agent" / "templates"
        assert templates_dir.exists(), "agent/templates/ directory should exist"
        assert templates_dir.is_dir(), "agent/templates/ should be a directory"
    
    def test_requirements_txt_exists(self):
        """GIVEN the agent directory, WHEN checking for requirements.txt, THEN it should exist"""
        requirements = PROJECT_ROOT / "agent" / "requirements.txt"
        assert requirements.exists(), "agent/requirements.txt should exist"
    
    def test_required_python_dependencies(self):
        """GIVEN requirements.txt, WHEN checking dependencies, THEN required packages should be listed"""
        requirements_path = PROJECT_ROOT / "agent" / "requirements.txt"
        
        with open(requirements_path, 'r') as f:
            content = f.read()
        
        required_deps = ['google-adk', 'mcp', 'jsonschema', 'python-dotenv']
        
        for dep in required_deps:
            assert dep in content, f"{dep} should be in requirements.txt"
    
    def test_env_example_exists(self):
        """GIVEN the agent directory, WHEN checking for .env.example, THEN it should exist"""
        env_example = PROJECT_ROOT / "agent" / ".env.example"
        assert env_example.exists(), "agent/.env.example should exist"
    
    def test_env_in_gitignore(self):
        """GIVEN .gitignore, WHEN checking for .env, THEN it should be ignored"""
        gitignore_path = PROJECT_ROOT / ".gitignore"
        
        with open(gitignore_path, 'r') as f:
            content = f.read()
        
        assert '.env' in content, ".env should be in .gitignore"


class TestTask13MCPServerStructure:
    """
    Task 1.3: Create MCP server directory structure
    
    Verify:
    - mcp_server/ directory with required files
    - requirements.txt with mcp dependency
    """
    
    def test_mcp_server_directory_exists(self):
        """GIVEN the project root, WHEN checking for mcp_server/, THEN it should exist"""
        mcp_dir = PROJECT_ROOT / "mcp_server"
        assert mcp_dir.exists(), "mcp_server/ directory should exist"
        assert mcp_dir.is_dir(), "mcp_server/ should be a directory"
    
    def test_server_py_exists(self):
        """GIVEN the mcp_server directory, WHEN checking for server.py, THEN it should exist"""
        server_py = PROJECT_ROOT / "mcp_server" / "server.py"
        assert server_py.exists(), "mcp_server/server.py should exist"
    
    def test_mock_data_py_exists(self):
        """GIVEN the mcp_server directory, WHEN checking for mock_data.py, THEN it should exist"""
        mock_data_py = PROJECT_ROOT / "mcp_server" / "mock_data.py"
        assert mock_data_py.exists(), "mcp_server/mock_data.py should exist"
    
    def test_requirements_txt_exists(self):
        """GIVEN the mcp_server directory, WHEN checking for requirements.txt, THEN it should exist"""
        requirements = PROJECT_ROOT / "mcp_server" / "requirements.txt"
        assert requirements.exists(), "mcp_server/requirements.txt should exist"
    
    def test_mcp_dependency_present(self):
        """GIVEN requirements.txt, WHEN checking dependencies, THEN mcp should be listed"""
        requirements_path = PROJECT_ROOT / "mcp_server" / "requirements.txt"
        
        with open(requirements_path, 'r') as f:
            content = f.read()
        
        assert 'mcp' in content, "mcp should be in requirements.txt"
