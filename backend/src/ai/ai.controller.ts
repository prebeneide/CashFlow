import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiController {
  constructor(private aiService: AiService) {}

  @Post('explain')
  async explainQuestion(
    @Body()
    body: {
      question: string;
      context: string;
      language?: string;
    },
  ) {
    const explanation = await this.aiService.explainOnboardingQuestion(
      body.question,
      body.context,
      body.language || 'nb',
    );

    return {
      explanation,
    };
  }

  @Post('chat')
  async chat(
    @Body()
    body: {
      message: string;
      chatHistory?: Array<{ role: string; content: string }>;
      context: {
        currentStep?: number;
        totalSteps?: number;
        stepNames?: string[];
        filledData?: Record<string, any>;
      };
      language?: string;
    },
  ) {
    const result = await this.aiService.chatWithContext(
      body.message,
      {
        ...body.context,
        chatHistory: body.chatHistory,
      },
      body.language || 'nb',
    );

    return result;
  }
}

