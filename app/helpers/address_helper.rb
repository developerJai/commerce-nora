module AddressHelper
  COUNTRIES = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Singapore',
    'United Arab Emirates'
  ].freeze

  COUNTRY_CODES = [
    ['+91', 'India (+91)'],
    ['+1', 'USA/Canada (+1)'],
    ['+44', 'UK (+44)'],
    ['+61', 'Australia (+61)'],
    ['+49', 'Germany (+49)'],
    ['+33', 'France (+33)'],
    ['+81', 'Japan (+81)'],
    ['+65', 'Singapore (+65)'],
    ['+971', 'UAE (+971)']
  ].freeze

  STATES_BY_COUNTRY = {
    'India' => [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
      'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
      'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
      'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
      'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Puducherry'
    ],
    'United States' => [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
      'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
      'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
      'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
      'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
      'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
      'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
      'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
      'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
      'West Virginia', 'Wisconsin', 'Wyoming'
    ],
    'United Kingdom' => [
      'England', 'Scotland', 'Wales', 'Northern Ireland'
    ],
    'Canada' => [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
      'Newfoundland and Labrador', 'Nova Scotia', 'Ontario',
      'Prince Edward Island', 'Quebec', 'Saskatchewan'
    ],
    'Australia' => [
      'New South Wales', 'Queensland', 'South Australia', 'Tasmania',
      'Victoria', 'Western Australia', 'Australian Capital Territory',
      'Northern Territory'
    ],

    'Germany' => [
      'Baden-Württemberg', 'Bavaria', 'Berlin', 'Brandenburg',
      'Bremen', 'Hamburg', 'Hesse', 'Lower Saxony',
      'Mecklenburg-Vorpommern', 'North Rhine-Westphalia',
      'Rhineland-Palatinate', 'Saarland', 'Saxony',
      'Saxony-Anhalt', 'Schleswig-Holstein', 'Thuringia'
    ],

    'France' => [
      'Auvergne-Rhône-Alpes', 'Bourgogne-Franche-Comté', 'Brittany',
      'Centre-Val de Loire', 'Corsica', 'Grand Est', 'Hauts-de-France',
      'Île-de-France', 'Normandy', 'Nouvelle-Aquitaine',
      'Occitanie', 'Pays de la Loire', 'Provence-Alpes-Côte d’Azur'
    ],

    'Japan' => [
      'Hokkaido', 'Aomori', 'Iwate', 'Miyagi', 'Akita', 'Yamagata', 'Fukushima',
      'Ibaraki', 'Tochigi', 'Gunma', 'Saitama', 'Chiba', 'Tokyo', 'Kanagawa',
      'Niigata', 'Toyama', 'Ishikawa', 'Fukui', 'Yamanashi', 'Nagano',
      'Gifu', 'Shizuoka', 'Aichi', 'Mie',
      'Shiga', 'Kyoto', 'Osaka', 'Hyogo', 'Nara', 'Wakayama',
      'Tottori', 'Shimane', 'Okayama', 'Hiroshima', 'Yamaguchi',
      'Tokushima', 'Kagawa', 'Ehime', 'Kochi',
      'Fukuoka', 'Saga', 'Nagasaki', 'Kumamoto', 'Oita', 'Miyazaki',
      'Kagoshima', 'Okinawa'
    ],

    'Singapore' => [
      'Central Region', 'North Region', 'North-East Region',
      'East Region', 'West Region'
    ],

    'United Arab Emirates' => [
      'Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman',
      'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah'
    ]
  }.freeze

  def country_options_for_select(selected = nil)
    options_for_select(COUNTRIES.map { |c| [c, c] }, selected || 'India')
  end

  def state_options_for_select(country, selected = nil)
    states = STATES_BY_COUNTRY[country] || []
    options_for_select(states.map { |s| [s, s] }, selected.presence)
  end

  def states_by_country_json
    STATES_BY_COUNTRY.to_json
  end

  def country_code_options_for_select(selected = nil)
    options_for_select(COUNTRY_CODES.map { |code, label| [label, code] }, selected || '+91')
  end

  # Map dial codes to ISO country codes for intl-tel-input
  DIAL_CODE_TO_ISO = {
    '+91' => 'in',
    '+1' => 'us',
    '+44' => 'gb',
    '+61' => 'au',
    '+49' => 'de',
    '+33' => 'fr',
    '+81' => 'jp',
    '+65' => 'sg',
    '+971' => 'ae'
  }.freeze

  def country_code_to_iso(country_code)
    DIAL_CODE_TO_ISO[country_code] || 'in'
  end
end
