declare module 'csv-stream' {
  import { EventEmitter } from 'events';
  import { Writable } from 'stream';

  interface StreamOptions {
    delimiter?: string;
    endLine?: string;
    columns?: string[];
    columnOffset?: number;
    escapeChar?: string;
    enclosedChar?: string;
  }

  interface CSVStream extends Writable, EventEmitter {
    columns: string[];
    columnLength: number;
    lineNo: number;
    columns(columns: unknown[]): CSVStream;
    columns(first: string, ...rest: string[]): CSVStream;

    // Event signatures - specific events first, then generic catch-all
    on(event: 'data', listener: (data: Record<string, string>) => void): this;
    on(event: 'column', listener: (key: string, value: string) => void): this;
    on(event: 'header', listener: (columns: string[]) => void): this;
    on(event: 'end', listener: () => void): this;
    on(event: 'error', listener: (error: Error) => void): this;
    on(event: 'close', listener: () => void): this;
    on(event: 'drain', listener: () => void): this;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    on(event: string | symbol, listener: (...args: any[]) => void): this;
  }

  function createStream(options?: StreamOptions): CSVStream;

  export { createStream, StreamOptions, CSVStream };
}
