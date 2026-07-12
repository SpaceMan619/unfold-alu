import 'package:flutter/material.dart';

import 'opportunity.dart';

const demoOpportunityDisclaimer =
    'Demo opportunity — not a real vacancy or company posting.';

class VentureOpportunitySeed {
  const VentureOpportunitySeed({
    required this.ventureName,
    required this.founders,
    required this.sector,
    required this.publicDescription,
    required this.sourceUrl,
    required this.aluConnection,
    required this.opportunity,
  });

  final String ventureName;
  final List<String> founders;
  final String sector;
  final String publicDescription;
  final String sourceUrl;
  final String aluConnection;
  final Opportunity opportunity;
}

const sourcedVentureOpportunitySeeds = [
  VentureOpportunitySeed(
    ventureName: 'Kayko',
    founders: ['Crepin Kayisire', 'Kevin Kayisire'],
    sector: 'Fintech',
    publicDescription:
        'A bookkeeping and financial visibility platform for African small businesses.',
    sourceUrl:
        'https://www.alueducation.com/kayko-the-alu-alumni-startup-empowering-african-smes/',
    aluConnection: 'Founded by ALU alumni.',
    opportunity: Opportunity(
      id: 'demo-kayko-flutter',
      role: 'Flutter product intern',
      startup: 'Kayko',
      summary: 'Shape mobile product ideas for small-business finance.',
      location: 'Kigali · Hybrid',
      commitment: '12 hrs / week',
      skills: ['Flutter', 'Firebase', 'UI testing'],
      match: 94,
      color: Color(0xff68ddc9),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Rwazi',
    founders: ['Joseph Rutakangwa'],
    sector: 'Market intelligence',
    publicDescription:
        'A technology venture that gathers and analyzes market data for decision-making.',
    sourceUrl: 'https://futurefest.alueducation.com/speakers/entrepreneurs',
    aluConnection: 'Founded by an ALU alumnus.',
    opportunity: Opportunity(
      id: 'demo-rwazi-data',
      role: 'Junior data insights intern',
      startup: 'Rwazi',
      summary: 'Turn market data into clear visual stories.',
      location: 'Remote',
      commitment: '10 hrs / week',
      skills: ['Python', 'Spreadsheets', 'Data storytelling'],
      match: 89,
      color: Color(0xff9fa8ff),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Plastic Venture',
    founders: ['Jimcale Faarah'],
    sector: 'Climate and recycling',
    publicDescription:
        'A Hargeisa recycling startup that collects plastic and converts it into paving bricks.',
    sourceUrl:
        'https://www.alueducation.com/jimcales-journey-sustaining-the-dream-of-a-better-africa/',
    aluConnection: 'Founded by an ALU student featured in an ALU impact story.',
    opportunity: Opportunity(
      id: 'demo-plastic-venture-operations',
      role: 'Community operations intern',
      startup: 'Plastic Venture',
      summary: 'Map a collection workflow and build an impact dashboard.',
      location: 'Hargeisa · Hybrid',
      commitment: '8 hrs / week',
      skills: ['Operations', 'Field research', 'Impact tracking'],
      match: 85,
      color: Color(0xff68ddc9),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Starlight',
    founders: ['Alice Mukashyaka'],
    sector: 'Clean energy',
    publicDescription:
        'A women-led model distributing locally made solar lanterns in Rwanda.',
    sourceUrl: 'https://www.alueducation.com/own-your-future/',
    aluConnection: 'Led by an ALU graduate featured on the ALU website.',
    opportunity: Opportunity(
      id: 'demo-starlight-growth',
      role: 'Clean energy growth intern',
      startup: 'Starlight',
      summary: 'Develop an outreach plan for a solar-light campaign.',
      location: 'Rwanda · Hybrid',
      commitment: '8 hrs / week',
      skills: ['Market research', 'Outreach', 'Impact reporting'],
      match: 83,
      color: Color(0xffffc66b),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Namirembe Sweater Makers',
    founders: ['Noah Walakira'],
    sector: 'Apparel and youth employment',
    publicDescription:
        'A community organization producing knitwear while training and employing young people.',
    sourceUrl: 'https://www.alueducation.com/own-your-future/',
    aluConnection: 'Founded by an ALU graduate featured on the ALU website.',
    opportunity: Opportunity(
      id: 'demo-namirembe-marketing',
      role: 'Digital marketing intern',
      startup: 'Namirembe Sweater Makers',
      summary: 'Create a content calendar for an ethical fashion campaign.',
      location: 'Uganda · Remote',
      commitment: '7 hrs / week',
      skills: ['Canva', 'Content', 'E-commerce'],
      match: 80,
      color: Color(0xffffc66b),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Smartel Agri-tech',
    founders: ['Israel Smart'],
    sector: 'Agritech',
    publicDescription:
        'An agritech venture addressing access, efficiency, and infrastructure challenges in farming communities.',
    sourceUrl:
        'https://www.alueducation.com/israel-smart-wins-un-habitat-scroll-of-honour-award/',
    aluConnection: 'Co-founded by an ALU student innovator.',
    opportunity: Opportunity(
      id: 'demo-smartel-research',
      role: 'Product research intern',
      startup: 'Smartel Agri-tech',
      summary: 'Plan farmer interviews and synthesize product insights.',
      location: 'Hybrid',
      commitment: '9 hrs / week',
      skills: ['UX research', 'Interviews', 'Analytics'],
      match: 87,
      color: Color(0xff68ddc9),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Sprint',
    founders: ['Don Daniel Mikenze'],
    sector: 'AI and logistics',
    publicDescription:
        'An AI-powered logistics platform supporting tracking, market access, and supply-chain decisions.',
    sourceUrl: 'https://www.alueducation.com/global-leadership-programme/',
    aluConnection:
        'Founded by an ALU student featured in its leadership programme.',
    opportunity: Opportunity(
      id: 'demo-sprint-mobile',
      role: 'Mobile logistics intern',
      startup: 'Sprint',
      summary:
          'Prototype a clear delivery-status experience for growing businesses.',
      location: 'Remote',
      commitment: '12 hrs / week',
      skills: ['Flutter', 'REST APIs', 'Maps'],
      match: 92,
      color: Color(0xff9fa8ff),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Signvrse',
    founders: ['Branice Kazira Otiende'],
    sector: 'Accessibility and AI',
    publicDescription:
        'A venture using AI-powered 3D sign-language avatars to bridge communication gaps for Deaf communities.',
    sourceUrl: 'https://www.alueducation.com/global-leadership-programme/',
    aluConnection: 'Co-founded by an ALU/ALX student.',
    opportunity: Opportunity(
      id: 'demo-signvrse-accessibility',
      role: 'Accessibility UX intern',
      startup: 'Signvrse',
      summary: 'Review product journeys against accessibility heuristics.',
      location: 'Remote',
      commitment: '8 hrs / week',
      skills: ['Figma', 'User research', 'Accessibility'],
      match: 88,
      color: Color(0xffffc66b),
    ),
  ),
  VentureOpportunitySeed(
    ventureName: 'Drifter Innovations',
    founders: ['Mahui Brian', 'Ian Christian'],
    sector: 'Smart retail and hardware',
    publicDescription:
        'A locally built smart-vending venture integrating refrigeration, software, and Mobile Money.',
    sourceUrl:
        'https://www.alueducation.com/smart-vending-machines-transform-retail-in-africa/',
    aluConnection:
        'Supported by the ALU Centre for Entrepreneurial Leadership.',
    opportunity: Opportunity(
      id: 'demo-drifter-iot',
      role: 'IoT software intern',
      startup: 'Drifter Innovations',
      summary:
          'Design a machine-health monitoring experience for smart retail.',
      location: 'Kigali · On-site',
      commitment: '10 hrs / week',
      skills: ['IoT', 'APIs', 'Monitoring'],
      match: 82,
      color: Color(0xff9fa8ff),
    ),
  ),
];
