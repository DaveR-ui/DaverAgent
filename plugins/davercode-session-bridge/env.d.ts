declare module "node:fs/promises" {
  export function writeFile(path: string, data: string, encoding: string): Promise<void>
  export function mkdir(path: string, options: { recursive: boolean }): Promise<void>
}

declare module "node:fs" {
  export function existsSync(path: string): boolean
  export function readFileSync(path: string, encoding: string): string
  export function statSync(path: string): { isDirectory(): boolean }
}

declare module "node:path" {
  export function join(...paths: string[]): string
  export function basename(path: string): string
  export function dirname(path: string): string
  export function resolve(...paths: string[]): string
}

declare module "node:crypto" {
  export function randomUUID(): string
}

declare module "node:os" {
  export function homedir(): string
}

declare module "node:url" {
  export function fileURLToPath(url: string): string
}

declare const process: {
  env: Record<string, string | undefined>
  stdout: { write(s: string): boolean | void }
  stderr: { write(s: string): boolean | void }
  exit(code?: number): never
}

interface ImportMeta {
  url: string
}
