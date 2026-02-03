import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private supabaseService: SupabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Mangler authorization header');
    }

    const token = authHeader.substring(7);

    try {
      const client = this.supabaseService.getClient();
      const {
        data: { user },
        error,
      } = await client.auth.getUser(token);

      if (error || !user) {
        throw new UnauthorizedException('Ugyldig token');
      }

      // Legg til bruker i request
      request.user = {
        id: user.id,
        email: user.email,
      };

      return true;
    } catch (error) {
      throw new UnauthorizedException('Kunne ikke verifisere token');
    }
  }
}

