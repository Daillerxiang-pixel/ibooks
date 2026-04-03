import { Controller, Get, Post, Param, Body, Req } from '@nestjs/common';
import { ChaptersService } from './chapters.service';

@Controller('chapters')
export class ChaptersController {
  constructor(private chaptersService: ChaptersService) {}

  @Get(':id')
  async content(@Param('id') id: number, @Req() req: any) {
    const userId = req.userId;
    return this.chaptersService.getContent(id, userId);
  }

  @Post(':id/read')
  async readProgress(@Param('id') id: number, @Body() body: { position?: number }, @Req() req: any) {
    return this.chaptersService.recordProgress(id, body.position || 0, req.userId);
  }
}
