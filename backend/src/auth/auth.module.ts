import { Module } from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';
import { SupabaseModule } from '../supabase/supabase.module';

@Module({
  imports: [SupabaseModule],
  providers: [JwtAuthGuard],
  exports: [JwtAuthGuard],
})
export class AuthModule {}

