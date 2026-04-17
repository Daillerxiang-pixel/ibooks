import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('ingest_sources')
export class IngestSource {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  sourceType: string;

  @Column({ type: 'text' })
  sourceId: string;

  @Column({ type: 'int', nullable: true })
  bookId: number;

  @Column({ type: 'text', nullable: true })
  sourceTitle: string;

  @Column({ type: 'text', nullable: true })
  sourceUrl: string;

  @Column({ type: 'int', default: 0 })
  sourceChapterCount: number;

  @Column({ type: 'int', default: 0 })
  fetchedChapterCount: number;

  @Column({ type: 'boolean', default: true })
  autoMonitor: boolean;

  @Column({ type: 'int', default: 60 })
  checkIntervalMinutes: number;

  @Column({ type: 'text', nullable: true })
  lastCheckAt: string;

  @Column({ type: 'text', nullable: true })
  lastFetchAt: string;

  @Column({ type: 'text', default: 'idle' })
  status: string;

  @Column({ type: 'text', nullable: true })
  lastError: string;

  @Column({ type: 'int', default: 1 })
  isActive: number;

  @CreateDateColumn()
  createdAt: Date;
}

@Entity('ingest_tasks')
export class IngestTask {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  sourceId: number;

  @Column({ type: 'text' })
  taskType: string;

  @Column({ type: 'text', default: 'pending' })
  status: string;

  @Column({ type: 'int', default: 0 })
  totalItems: number;

  @Column({ type: 'int', default: 0 })
  processedItems: number;

  @Column({ type: 'int', default: 0 })
  failedItems: number;

  @Column({ type: 'text', nullable: true })
  log: string;

  @Column({ type: 'text', nullable: true })
  startedAt: string;

  @Column({ type: 'text', nullable: true })
  completedAt: string;

  @Column({ type: 'text', nullable: true })
  error: string;

  @CreateDateColumn()
  createdAt: Date;
}
