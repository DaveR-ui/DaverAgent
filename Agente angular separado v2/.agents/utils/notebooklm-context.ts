/**
 * NotebookLM Context Helper
 *
 * Provides easy access to the Fire Extinguisher Management System
 * documentation stored in NotebookLM through MCP integration.
 *
 * @module NotebookLMContext
 */

import notebookConfig from '../config/notebooklm.json'

/**
 * NotebookLM notebook identifier for the firefighters system
 */
export const NOTEBOOK_ID = notebookConfig.notebook.id

/**
 * Query categories for common documentation lookups
 */
export enum QueryCategory {
  ARCHITECTURE = 'architecture',
  DATABASE = 'database',
  BUSINESS_LOGIC = 'business_logic',
  UI_UX = 'ui_ux',
  DEPLOYMENT = 'deployment',
  VALIDATION = 'validation',
}

/**
 * Pre-defined query templates for common questions
 */
export const QUERY_TEMPLATES = {
  [QueryCategory.ARCHITECTURE]: {
    general: 'Describe the overall system architecture and technology stack',
    cloudSetup: 'How should the Google Cloud infrastructure be configured?',
    authentication: 'What is the authentication strategy and implementation?',
  },
  [QueryCategory.DATABASE]: {
    schema: 'What is the complete database schema and entity relationships?',
    entity: (entityName: string) =>
      `Describe the ${entityName} table structure and business rules`,
    relationships: (tableName: string) =>
      `What are the foreign key relationships for the ${tableName} table?`,
    validation: 'What are the data validation rules and constraints?',
  },
  [QueryCategory.BUSINESS_LOGIC]: {
    dateCalculation: 'How should automatic date calculation be implemented?',
    duplicateDetection: 'How does the duplicate detection system work?',
    printing: 'What are the printing module requirements and formats?',
    shortcuts: 'What keyboard shortcuts should be implemented?',
  },
  [QueryCategory.UI_UX]: {
    design: 'What are the UI/UX design principles and guidelines?',
    workflows: 'What are the main user workflows and navigation patterns?',
    responsive: 'What are the responsive design requirements?',
    accessibility: 'What accessibility features should be implemented?',
  },
  [QueryCategory.DEPLOYMENT]: {
    cloudRun: 'How should the backend be deployed to Cloud Run?',
    firebase:
      'What Firebase services are used and how should they be configured?',
    database: 'How should Cloud SQL be set up and configured?',
  },
  [QueryCategory.VALIDATION]: {
    capacity: 'How does the capacity validation system work?',
    duplicates: 'What duplicate detection rules should be enforced?',
    dates: 'What date validation rules are required?',
  },
} as const

/**
 * NotebookLM context helper class
 *
 * Note: This is a TypeScript interface definition. The actual MCP queries
 * should be made through the MCP server using the notebooklm-mcp tools.
 *
 * @example
 * // In your agent workflow:
 * const answer = await mcp_notebooklm-mcp_notebook_query({
 *   notebook_id: NOTEBOOK_ID,
 *   query: NotebookLMContext.getQuery('database', 'entity', 'clientes')
 * });
 */
export class NotebookLMContext {
  /**
   * Get a pre-defined query template
   */
  static getQuery(
    category: QueryCategory,
    template: string,
    ...args: string[]
  ): string {
    const categoryTemplates = QUERY_TEMPLATES[category]
    if (!categoryTemplates) {
      throw new Error(`Unknown query category: ${category}`)
    }

    const queryTemplate = categoryTemplates[template]
    if (!queryTemplate) {
      throw new Error(`Unknown template: ${template} in category: ${category}`)
    }

    if (typeof queryTemplate === 'function') {
      return queryTemplate(...args)
    }

    return queryTemplate
  }

  /**
   * Get all source IDs by category
   */
  static getSourcesByCategory(category: string): string[] {
    return notebookConfig.sources
      .filter((source) => source.category === category)
      .map((source) => source.id)
  }

  /**
   * Get notebook metadata
   */
  static getNotebookInfo() {
    return notebookConfig.notebook
  }

  /**
   * Get MCP integration status
   */
  static isMCPEnabled(): boolean {
    return notebookConfig.mcp_integration.enabled
  }

  /**
   * Get path to context documentation
   */
  static getContextFilePath(): string {
    return notebookConfig.mcp_integration.context_file
  }
}

/**
 * Common query shortcuts for quick access
 */
export const CommonQueries = {
  // Database queries
  getClientSchema: () =>
    NotebookLMContext.getQuery(QueryCategory.DATABASE, 'entity', 'clientes'),

  getMatafuegoSchema: () =>
    NotebookLMContext.getQuery(QueryCategory.DATABASE, 'entity', 'matafuegos'),

  getTarjetaSchema: () =>
    NotebookLMContext.getQuery(QueryCategory.DATABASE, 'entity', 'tarjetas'),

  getConfigVencimientos: () =>
    NotebookLMContext.getQuery(
      QueryCategory.DATABASE,
      'entity',
      'config_vencimientos',
    ),

  // Business logic queries
  getDateCalculationLogic: () =>
    NotebookLMContext.getQuery(QueryCategory.BUSINESS_LOGIC, 'dateCalculation'),

  getDuplicateDetectionLogic: () =>
    NotebookLMContext.getQuery(
      QueryCategory.BUSINESS_LOGIC,
      'duplicateDetection',
    ),

  getKeyboardShortcuts: () =>
    NotebookLMContext.getQuery(QueryCategory.BUSINESS_LOGIC, 'shortcuts'),

  // UI/UX queries
  getDesignPrinciples: () =>
    NotebookLMContext.getQuery(QueryCategory.UI_UX, 'design'),

  getUserWorkflows: () =>
    NotebookLMContext.getQuery(QueryCategory.UI_UX, 'workflows'),

  // Architecture queries
  getArchitectureOverview: () =>
    NotebookLMContext.getQuery(QueryCategory.ARCHITECTURE, 'general'),

  getCloudSetup: () =>
    NotebookLMContext.getQuery(QueryCategory.ARCHITECTURE, 'cloudSetup'),
} as const

/**
 * Source categories for filtered queries
 */
export const SourceCategories = {
  STRATEGIC: 'strategic',
  TECHNICAL: 'technical',
  OPERATIONAL: 'operational',
  DEPLOYMENT: 'deployment',
  UI_REFERENCE: 'ui_reference',
} as const

/**
 * Helper to get strategic planning sources
 */
export const getStrategicSources = () =>
  NotebookLMContext.getSourcesByCategory(SourceCategories.STRATEGIC)

/**
 * Helper to get technical documentation sources
 */
export const getTechnicalSources = () =>
  NotebookLMContext.getSourcesByCategory(SourceCategories.TECHNICAL)

/**
 * Helper to get UI reference sources (legacy screenshots)
 */
export const getUIReferenceSources = () =>
  NotebookLMContext.getSourcesByCategory(SourceCategories.UI_REFERENCE)

export default NotebookLMContext
