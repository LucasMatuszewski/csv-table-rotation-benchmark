declare module 'csv-stream' {
  import { EventEmitter } from 'events';

  interface StreamOptions {
    delimiter?: string;
    endLine?: string;
    columns?: string[];
    columnOffset?: number;
    escapeChar?: string;
    enclosedChar?: string;
  }

  interface CSVStream extends NodeJS.ReadWriteStream {
    on(event: 'data', listener: (data: Record<string, string>) => void): this;
    on(event: 'column', listener: (key: string, value: string) => void): this;
    on(event: 'header', listener: (columns: string[]) => void): this;
    on(event: 'end', listener: () => void): this;
    on(event: 'error', listener: (error: Error) => void): this;
    on(event: 'close', listener: () => void): this;
    on(event: 'drain', listener: () => void): this;
    on(event: string, listener: (...args: any[]) => void): this;
  }

  function createStream(options?: StreamOptions): CSVStream;

  export { createStream, StreamOptions, CSVStream };
}
