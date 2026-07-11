declare module "node:fs/promises" {
  export function writeFile(path: string, data: string, encoding: string): Promise<void>
  export function mkdir(path: string, options: { recursive: boolean }): Promise<void>
}

declare module "node:path" {
  export function join(...paths: string[]): string
  export function basename(path: string): string
}

declare module "node:crypto" {
  export function randomUUID(): string
}

declare module "node:os" {
  export function homedir(): string
}

declare const process: {
  env: Record<string, string | undefined>
}
