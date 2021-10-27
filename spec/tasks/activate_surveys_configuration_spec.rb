require 'pry'
require 'rails_helper'

Rails.application.load_tasks

RSpec.describe 'setting_activate_surveys_configuration' do
  context 'activate surveys configuration tasks' do
    company = ['BancoEstado - Delivery Tarjetas', 'REDGLOBAL', 'Copec',
               'C/Moran', 'Club Social y Deportivo Colo-Colo', 'esderulos',
               'Boss Babe Beauty', 'Buale', 'The Body Shop',
               'Rotter & Krauss', 'Privilege', 'SHIVSAI SPA', 'DBS Chile',
               'Okwu', 'Page One', 'kine-store',
               'B2B WEB DISTRIBUICAO DO PRODUTOS CHILE SPA', 'MyCOCOS',
               'Raindoor', 'Organik Cosmetics', 'SUMUP', 'Tua Retail',
               'ALISHA PERFUMES', 'La Planchetta Chile SPA',
               'Rulos chile spa', 'IVMEDICAL', 'Citrola', 'Novatex SPA',
               'Club de Perros y Gatos', 'ORX FIT', 'Scorpi', 'Grylan',
               'Lgnd Spa', 'HERBOLARIA DE CHILE S.A. BODEGA',
               'gosh babe spa', 'KANKA', 'Prestige SpA', 'Musicland',
               'Your Goal', 'BebeAComer', 'Barbizon', 'Oh My Skin SpA',
               'BEESE', 'Amantani Tienda', 'Naay', 'sosmart sa',
               'Trenzaduría Fraile', 'Chantilly', 'CafeStore', 'Uma Baby',
               'Agencia Salmón SpA', 'Inspirada Hecho a Mano',
               'RH-STORES SpA. (Village y Argos Party)', 'Cotillón Activarte',
               'Revesderecho', 'ClearSkin Chile', 'Vaporizadores Chile',
               'Mali Shop', 'Comercializadora Needle S.A.',
               'Comercial Giovo Limitada', 'Espesales', 'VAL SUMINISTROS SPA',
               'Trip Helmets', 'Casa del Cuenco', 'HILANDERIA MAISA S.A.',
               'Simmedical', 'Winkler Nutrition', 'GNOMO', 'MioBioChile',
               'Galeria Impresionarte', 'DEMARIE SPA', 'TPS',
               'MG SOLUCIONES TI SPA', 'Papaya Bragas SPA',
               'Lucky Diamonds SpA', 'Saint-malē', 'Casa Moda', 'Ortotek',
               'Maikra SPA', 'MDL Store', 'DER EDICIONES', 'El Libero',
               'Nostalgic', 'Outlet Médico', 'CG Cosmetics',
               'Libreria Peniel', 'VESSI SpA', 'natural detox ', 'Mi Placard',
               'Bazar Fungi', 'Mepsystem & ResinArt', 'INDAH STORE',
               'Aritrans', 'Secretos de Amor', 'MiFoto', 'StreetMachine',
               'EDITORIAL AMANUTA', 'Pethome', 'Automatizate ', 'Black Crown',
               'Ortomolecular Chile', 'mamás mateas', 'crissaraos',
               'Rosa Bergamota', 'Indigo de Papel',
               'Peluquerías Integrales S.A.', 'Detogni', 'BY DELUXE'].sample

    it "is available configuration to mail surveys csat for #{company}" do
      Rake::Task['setting:activate_surveys_configuration'].invoke
      expect(Setting.joins('LEFT JOIN entities entities ON entities.actable_id = settings.company_id')
                    .where(entities: { name: company },
                           settings: { service_id: 6 })
                    .first
                    .configuration['notification']['buyer']['mail']['surveys']['csat']['active']).to eq(true)
    end
  end
end
