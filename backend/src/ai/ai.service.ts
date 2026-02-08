import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

@Injectable()
export class AiService {
  private openai: OpenAI | null = null;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY');
    if (apiKey) {
      this.openai = new OpenAI({
        apiKey: apiKey,
      });
    }
  }

  async explainOnboardingQuestion(
    question: string,
    context: string,
    language: string = 'nb',
  ): Promise<string> {
    if (!this.openai) {
      return 'Tjenesten er ikke tilgjengelig. Vennligst kontakt support.';
    }

    const prompt = `Du er en hjelpsom regnskapsassistent som hjelper norske bedriftseiere med å sette opp regnskapssystemet sitt.

Spørsmål: ${question}
Kontekst: ${context}

Gi en tydelig, enkel forklaring på norsk som:
1. Forklarer hva spørsmålet betyr i enkle ord
2. Hvor brukeren kan finne denne informasjonen
3. Hva som skjer hvis de velger feil (konsekvenser)
4. Gir konkrete eksempler når det er relevant

Hold svaret kort og konsist (maks 200 ord). Skriv på norsk.`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content:
              'Du er en hjelpsom og vennlig regnskapsassistent som forklarer komplekse regnskapsbegreper på en enkel måte.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        max_tokens: 300,
        temperature: 0.7,
      });

      return completion.choices[0]?.message?.content || 'Kunne ikke generere forklaring.';
    } catch (error) {
      console.error('OpenAI error:', error);
      return 'Kunne ikke generere forklaring akkurat nå. Vennligst prøv igjen.';
    }
  }

  async chatWithContext(
    message: string,
    context: {
      currentStep?: number;
      totalSteps?: number;
      stepNames?: string[];
      filledData?: Record<string, any>;
      chatHistory?: Array<{ role: string; content: string }>;
    },
    language: string = 'nb',
  ): Promise<{ response: string; suggestions?: any[] }> {
    if (!this.openai) {
      return {
        response: 'Tjenesten er ikke tilgjengelig. Vennligst kontakt support.',
      };
    }

    const filledData = context.filledData || {};
    const currentStep = context.currentStep ?? 0;
    const totalSteps = context.totalSteps ?? 4;
    const stepNames = context.stepNames || [];
    const chatHistory = context.chatHistory || [];

    // Bygg detaljert kontekst-streng
    const filledDataSummary = Object.entries(filledData)
      .filter(([_, value]) => value != null && value !== '')
      .map(([key, value]) => {
        const labels: Record<string, string> = {
          companyName: 'Bedriftsnavn',
          organizationNumber: 'Organisasjonsnummer',
          legalForm: 'Juridisk form',
          fiscalYearStart: 'Regnskapsår start',
          accountingStandard: 'Regnskapsstandard',
          vatRegistered: 'MVA-registrert',
          vatNumber: 'MVA-nummer',
          industry: 'Bransje',
        };
        return `  - ${labels[key] || key}: ${value}`;
      })
      .join('\n') || '  (ingen data fylt ut ennå)';

    const currentStepName = stepNames[currentStep] || `Steg ${currentStep + 1}`;

    const contextString = `
Du er en hjelpsom og vennlig regnskapsassistent som hjelper norske bedriftseiere med å sette opp regnskapssystemet sitt gjennom en naturlig chat-dialog.

Nåværende situasjon:
- Nåværende steg: ${currentStepName} (${currentStep + 1}/${totalSteps})
- Fylt ut så langt:
${filledDataSummary}

Onboarding-prosess (i rekkefølge):
1. Grunnleggende informasjon (bedriftsnavn, org.nr, juridisk form) - ${filledData.companyName && filledData.legalForm ? '✅ Fylt ut' : '❌ Mangler'}
2. Regnskapsinformasjon (regnskapsår, regnskapsstandard) - ${filledData.accountingStandard ? '✅ Fylt ut' : '❌ Mangler'}
3. MVA (MVA-registrert, MVA-nummer) - ${filledData.vatRegistered !== undefined ? '✅ Fylt ut' : '❌ Mangler'}
4. Bransje og aktivitet - ${filledData.industry ? '✅ Fylt ut' : '❌ Mangler'}

Din oppgave:
1. Svar på brukerens spørsmål på en enkel og forståelig måte (maks 150 ord)
2. Du har tilgang til hele chat-historikken, så husk hva brukeren har sagt tidligere
3. Hvis brukeren spør om noe som allerede er fylt ut, referer til det
4. Forklar konsekvenser av valg hvis brukeren spør
5. Vær proaktiv - hvis brukeren virker usikker, foreslå valg eller forklar mer
6. Når alt er fylt ut, bekreft og si at de kan fullføre onboarding

Viktig:
- Vær vennlig og støttende
- Forklar i enkle ord
- Bruk informasjonen fra chat-historikken for å gi relevante svar
- Hvis brukeren spør om noe som ikke er relevant for onboarding, forklar at du fokuserer på onboarding nå, men kan hjelpe med det senere

Skriv på norsk.
`;

    const systemPrompt = `Du er en hjelpsom og vennlig regnskapsassistent. Du hjelper norske bedriftseiere med å sette opp regnskapssystemet sitt gjennom en naturlig chat-dialog. Du husker hele samtalehistorikken og kan svare på spørsmål basert på hva brukeren har sagt tidligere.`;

    // Bygg meldinger-array med chat-historikk
    const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
      {
        role: 'system',
        content: systemPrompt,
      },
    ];

    // Legg til chat-historikk (siste 10 meldinger for å unngå for lange prompts)
    const recentHistory = chatHistory.slice(-10);
    for (const msg of recentHistory) {
      if (msg.role === 'user' || msg.role === 'assistant') {
        messages.push({
          role: msg.role as 'user' | 'assistant',
          content: msg.content,
        });
      }
    }

    // Legg til kontekst og nåværende melding
    messages.push({
      role: 'user',
      content: `${contextString}\n\nBrukerens melding: ${message}`,
    });

    try {
      const completion = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: messages,
        max_tokens: 500,
        temperature: 0.7,
      });

      const response =
        completion.choices[0]?.message?.content ||
        'Beklager, jeg kunne ikke generere et svar akkurat nå.';

      // Generer forslag basert på kontekst
      const suggestions = await this._generateSuggestions(
        currentStep,
        filledData,
        message,
      );

      return {
        response,
        suggestions: suggestions.length > 0 ? suggestions : undefined,
      };
    } catch (error) {
      console.error('OpenAI error:', error);
      return {
        response:
          'Beklager, jeg kunne ikke behandle meldingen din akkurat nå. Vennligst prøv igjen.',
      };
    }
  }

  private async _generateSuggestions(
    currentStep: string,
    filledData: Record<string, any>,
    userMessage: string,
  ): Promise<any[]> {
    const suggestions: any[] = [];

    // Generer forslag basert på nåværende steg
    if (currentStep === 'company_name' && !filledData.companyName) {
      // Ingen forslag for bedriftsnavn - brukeren må skrive det selv
    } else if (currentStep === 'legal_form' && !filledData.legalForm) {
      suggestions.push(
        { type: 'fill_field', label: 'AS (Aksjeselskap)', data: { field: 'legalForm', value: 'AS' } },
        { type: 'fill_field', label: 'ENK (Enkeltpersonforetak)', data: { field: 'legalForm', value: 'ENK' } },
        { type: 'fill_field', label: 'DA (Ansvarlig selskap)', data: { field: 'legalForm', value: 'DA' } },
        { type: 'fill_field', label: 'ANS (Ansvarlig selskap)', data: { field: 'legalForm', value: 'ANS' } },
      );
    } else if (currentStep === 'accounting_standard' && !filledData.accountingStandard) {
      suggestions.push(
        { type: 'fill_field', label: 'NRS (Norsk Regnskapsstandard)', data: { field: 'accountingStandard', value: 'NRS' } },
        { type: 'fill_field', label: 'IFRS (International Financial Reporting Standards)', data: { field: 'accountingStandard', value: 'IFRS' } },
        { type: 'fill_field', label: 'K3 (Kunngjøringsforskriften)', data: { field: 'accountingStandard', value: 'K3' } },
      );
    } else if (currentStep === 'vat' && filledData.vatRegistered === undefined) {
      suggestions.push(
        { type: 'fill_field', label: 'Ja, jeg er MVA-registrert', data: { field: 'vatRegistered', value: true } },
        { type: 'fill_field', label: 'Nei, jeg er ikke MVA-registrert', data: { field: 'vatRegistered', value: false } },
      );
    } else if (currentStep === 'industry' && !filledData.industry) {
      suggestions.push(
        { type: 'fill_field', label: 'Konsulenttjenester', data: { field: 'industry', value: 'Konsulenttjenester' } },
        { type: 'fill_field', label: 'Varehandel', data: { field: 'industry', value: 'Varehandel' } },
        { type: 'fill_field', label: 'Restaurant', data: { field: 'industry', value: 'Restaurant' } },
        { type: 'fill_field', label: 'Bygge og anlegg', data: { field: 'industry', value: 'Bygge og anlegg' } },
        { type: 'fill_field', label: 'Annet', data: { field: 'industry', value: 'Annet' } },
      );
    }

    return suggestions;
  }
}

