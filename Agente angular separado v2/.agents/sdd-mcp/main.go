package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

func main() {
	// Determinar la ruta de las skills con múltiples estrategias de resolución
	var skillsPath string

	// 1. Variable de entorno (prioridad máxima)
	if envPath := os.Getenv("SDD_SKILLS_PATH"); envPath != "" {
		skillsPath = envPath
	} else {
		// 2. Working directory + .agents/skills (compatible con OpenCode)
		wd, _ := os.Getwd()
		skillsPath = filepath.Join(wd, ".agents", "skills")
	}

	// Validar que el directorio existe
	if _, err := os.Stat(skillsPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Warning: skills directory not found at %s\n", skillsPath)
	}

	// 1. Crear el servidor MCP
	s := server.NewMCPServer(
		"SDD Knowledge Server",
		"1.0.0",
	)

	// 2. Registrar Recursos (Resources)
	s.AddResource(
		mcp.NewResource(
			"sdd://skills/{folder}",
			"Contenido de una Skill específica",
		),
		func(ctx context.Context, request mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {
			uri := request.Params.URI
			folder := strings.TrimPrefix(uri, "sdd://skills/")
			
			// Construir ruta al archivo SKILL.md
			filePath := filepath.Join(skillsPath, folder, "SKILL.md")
			
			data, err := os.ReadFile(filePath)
			if err != nil {
				return nil, fmt.Errorf("no se pudo leer la skill %s: %v", folder, err)
			}
			
			content := mcp.TextResourceContents{
				URI:      uri,
				MIMEType: "text/markdown",
				Text:     string(data),
			}
			
			return []mcp.ResourceContents{content}, nil
		},
	)

	// Tool: list_skills — lista todas las skills disponibles
	s.AddTool(mcp.NewTool("list_skills",
		mcp.WithDescription("Lista todas las skills disponibles en el Hub de Conocimiento con su categoría y nombre"),
	), func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		var skills []string

		err := filepath.Walk(skillsPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}
			if !info.IsDir() && strings.EqualFold(info.Name(), "SKILL.md") {
				relPath, _ := filepath.Rel(skillsPath, path)
				// Extraer el nombre de la carpeta (formato: categoria-nombre)
				parts := strings.Split(filepath.Dir(relPath), string(filepath.Separator))
				folderName := parts[len(parts)-1]
				skills = append(skills, folderName)
			}
			return nil
		})

		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("error listando skills: %v", err)), nil
		}

		if len(skills) == 0 {
			return mcp.NewToolResultText("No se encontraron skills en el Hub de Conocimiento."), nil
		}

		return mcp.NewToolResultText(fmt.Sprintf("Skills disponibles (%d):\n- %s", len(skills), strings.Join(skills, "\n- "))), nil
	})

	// Tool: read_skill — lee el contenido completo de una skill
	s.AddTool(mcp.NewTool("read_skill",
		mcp.WithDescription("Lee el contenido completo de una skill específica del Hub de Conocimiento"),
		mcp.WithString("skill_name", mcp.Required(), mcp.Description("Nombre de la carpeta de la skill (ej: p1-framework-angular-component)")),
	), func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args, ok := request.Params.Arguments.(map[string]any)
		if !ok {
			return mcp.NewToolResultError("invalid arguments"), nil
		}

		skillName := args["skill_name"].(string)
		filePath := filepath.Join(skillsPath, skillName, "SKILL.md")

		data, err := os.ReadFile(filePath)
		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("no se pudo leer la skill '%s': %v", skillName, err)), nil
		}

		return mcp.NewToolResultText(string(data)), nil
	})

	// Tool: search_sdd — busca contenido en las skills
	s.AddTool(mcp.NewTool("search_sdd",
		mcp.WithDescription("Busca términos dentro de los archivos SKILL.md del Hub de Conocimiento"),
		mcp.WithString("query", mcp.Required(), mcp.Description("Término o frase a buscar")),
	), func(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args, ok := request.Params.Arguments.(map[string]any)
		if !ok {
			return mcp.NewToolResultError("invalid arguments"), nil
		}
		
		query := strings.ToLower(args["query"].(string))
		var results []string

		// Caminar por el directorio de skills para buscar el término
		err := filepath.Walk(skillsPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil // Continuar si hay error en un archivo específico
			}
			if !info.IsDir() && strings.HasSuffix(info.Name(), ".md") {
				content, err := os.ReadFile(path)
				if err == nil {
					if strings.Contains(strings.ToLower(string(content)), query) {
						relPath, _ := filepath.Rel(skillsPath, path)
						results = append(results, relPath)
					}
				}
			}
			return nil
		})

		if err != nil {
			return mcp.NewToolResultError(fmt.Sprintf("error durante la búsqueda: %v", err)), nil
		}

		if len(results) == 0 {
			return mcp.NewToolResultText("No se encontraron coincidencias en el Hub de Conocimiento."), nil
		}

		return mcp.NewToolResultText(fmt.Sprintf("Coincidencias encontradas en:\n- %s", strings.Join(results, "\n- "))), nil
	})

	// 4. Iniciar el servidor en modo stdio
	if err := server.ServeStdio(s); err != nil {
		fmt.Fprintf(os.Stderr, "Error ejecutando el servidor: %v\n", err)
		os.Exit(1)
	}
}
