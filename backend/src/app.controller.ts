import { Controller, Get, UseGuards } from '@nestjs/common';
import { AppService } from './app.service';
import { SupabaseService } from './supabase/supabase.service';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { CurrentUser } from './auth/current-user.decorator';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly supabaseService: SupabaseService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      message: 'CashFlow API is running',
    };
  }

  @Get('supabase/test')
  async testSupabase() {
    try {
      const client = this.supabaseService.getClient();
      const { data, error } = await client.from('_test').select('*').limit(1);
      
      return {
        status: 'connected',
        message: 'Supabase er tilkoblet',
        hasError: !!error,
        error: error?.message || null,
      };
    } catch (error) {
      return {
        status: 'error',
        message: 'Supabase ikke konfigurert eller feil oppstod',
        error: error.message,
      };
    }
  }

  @Get('auth/me')
  @UseGuards(JwtAuthGuard)
  getCurrentUser(@CurrentUser() user: any) {
    return {
      message: 'Autentisert bruker',
      user: {
        id: user.id,
        email: user.email,
      },
    };
  }

  @Get('database/test')
  async testDatabase() {
    try {
      const client = this.supabaseService.getClient();
      
      // Test at vi kan lese fra users-tabellen
      const { data: users, error: usersError } = await client
        .from('users')
        .select('id, email')
        .limit(1);
      
      // Test at vi kan lese fra company_profiles
      const { data: companies, error: companiesError } = await client
        .from('company_profiles')
        .select('id, name')
        .limit(1);
      
      // Test at vi kan lese fra transactions
      const { data: transactions, error: transactionsError } = await client
        .from('transactions')
        .select('id, status')
        .limit(1);
      
      return {
        status: 'connected',
        message: 'Database-tilkobling fungerer',
        tables: {
          users: {
            accessible: !usersError,
            count: users?.length || 0,
            error: usersError?.message || null,
          },
          company_profiles: {
            accessible: !companiesError,
            count: companies?.length || 0,
            error: companiesError?.message || null,
          },
          transactions: {
            accessible: !transactionsError,
            count: transactions?.length || 0,
            error: transactionsError?.message || null,
          },
        },
      };
    } catch (error) {
      return {
        status: 'error',
        message: 'Database-tilkobling feilet',
        error: error.message,
      };
    }
  }
}

