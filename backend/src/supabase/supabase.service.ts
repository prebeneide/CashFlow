import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private supabaseClient: SupabaseClient;
  private supabaseAdminClient: SupabaseClient;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseAnonKey = this.configService.get<string>('SUPABASE_ANON_KEY');
    const supabaseServiceRoleKey = this.configService.get<string>(
      'SUPABASE_SERVICE_ROLE_KEY',
    );

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error('Supabase URL og Anon Key må være satt i environment variables');
    }

    // Klient for bruker-operasjoner
    this.supabaseClient = createClient(supabaseUrl, supabaseAnonKey);

    // Admin-klient for server-side operasjoner (hvis service role key er satt)
    if (supabaseServiceRoleKey) {
      this.supabaseAdminClient = createClient(
        supabaseUrl,
        supabaseServiceRoleKey,
      );
    }
  }

  getClient(): SupabaseClient {
    return this.supabaseClient;
  }

  getAdminClient(): SupabaseClient | null {
    return this.supabaseAdminClient || null;
  }
}

