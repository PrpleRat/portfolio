export const HELP = {
  splitType: {
    title: 'Type de split',
    text:
      'Master uniquement : tu répartis seulement les droits sur l’enregistrement (le fichier audio). C’est le cas le plus courant en session rap.\n\n' +
      'Master + Publishing : tu répartis aussi les droits d’auteur — composition (beat, mélodie) et paroles. À utiliser quand chacun est crédité comme compositeur ou parolier auprès de la SACEM.',
  },
  masterShare: {
    title: 'Part Master (%)',
    text:
      'Pourcentage de propriété sur l’enregistrement sonore fini — le fichier audio du morceau.\n\n' +
      'Exemple : 50 % master = tu possèdes la moitié de l’enregistrement. En rap, c’est souvent le producteur et l’artiste qui se partagent le master.',
  },
  publishingShare: {
    title: 'Part Publishing (%)',
    text:
      'Pourcentage sur les droits d’auteur : composition (instrumental, mélodie) et paroles.\n\n' +
      'Géré séparément du master via ta PRO (SACEM en France). Un beatmaker peut avoir 30 % publishing et 50 % master, par exemple.',
  },
  isrc: {
    title: 'ISRC',
    text:
      'Code international unique du morceau. Il est attribué par ta plateforme de distribution (DistroKid, TuneCore, etc.) une fois le titre distribué.',
  },
} as const;
