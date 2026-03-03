const WEAK_SEQUENCES = [
  'qwertyuiop', 'qwertzuiop', 'asdfghjkl', 'zxcvbnm',
  'qazwsxedc', 'qweasdzxc', '1qaz2wsx', 'qazxswedc',
  'abcdefgh', 'abcdefghij', 'zyxwvuts',
  '1234567890', '0987654321', '12345678', '87654321',
  '11111111', '22222222', '33333333', 'aaaaaaaa', 'bbbbbbbb',
];

const COMMON_BASES = [
  'password', 'passw0rd', 'p@ssword', 'p@ssw0rd',
  'qwerty', 'qwert', 'asdfgh', 'zxcvbn',
  'iloveyou', 'letmein', 'welcome', 'monkey',
  'dragon', 'master', 'admin', 'login',
  'superman', 'batman', 'football', 'baseball',
  'sunshine', 'princess', 'access', 'shadow',
  'michael', 'jennifer', 'thomas', 'charlie',
  '1q2w3e4r', 'q1w2e3r4', '1q2w3e',
];

/**
 * Returns null if password is strong, or an error string if weak.
 * @param {string} pw - the password
 * @param {string} [username] - optional username to check against
 * @returns {string|null}
 */
function passwordStrengthError(pw, username) {
  if (!pw || typeof pw !== 'string') return 'Құпия сөз жоқ';
  if (pw.length < 8)   return 'Кем дегенде 8 таңба болуы керек';
  if (pw.length > 128) return 'Құпия сөз тым ұзын (макс. 128 таңба)';
  if (!/[a-z]/.test(pw)) return 'Кіші әріп (a-z) болуы керек';
  if (!/[A-Z]/.test(pw)) return 'Бас әріп (A-Z) болуы керек';
  if (!/[0-9]/.test(pw)) return 'Сан (0-9) болуы керек';
  if (!/[!@#$%^&*()\-_=+\[\]{};:'",.<>\/\\?|`~]/.test(pw)) {
    return 'Арнайы таңба болуы керек (!@#$%...)';
  }

  const lower = pw.toLowerCase();

  // Repeated characters (3+ same in a row)
  if (/(.)\1{2,}/.test(pw)) {
    return 'Қайталанатын таңбалар тым көп (aaa, 111...)';
  }

  // Password contains username
  if (username && lower.includes(username.toLowerCase())) {
    return 'Құпия сөзде пайдаланушы аты болмауы керек';
  }

  // Keyboard / number sequences (check any 4-char substring)
  for (const seq of WEAK_SEQUENCES) {
    for (let i = 0; i <= seq.length - 4; i++) {
      if (lower.includes(seq.slice(i, i + 4))) {
        return 'Клавиатура тізбегін пайдалануға болмайды (qwer, asdf, 1234...)';
      }
    }
    const rev = seq.split('').reverse().join('');
    for (let i = 0; i <= rev.length - 4; i++) {
      if (lower.includes(rev.slice(i, i + 4))) {
        return 'Клавиатура тізбегін пайдалануға болмайды (qwer, asdf, 1234...)';
      }
    }
  }

  // Normalize leet-speak substitutions, then check common bases
  const normalized = lower
    .replace(/0/g, 'o').replace(/1/g, 'i').replace(/3/g, 'e')
    .replace(/4/g, 'a').replace(/5/g, 's').replace(/8/g, 'b')
    .replace(/@/g, 'a').replace(/\$/g, 's').replace(/!/g, 'i');

  for (const base of COMMON_BASES) {
    if (normalized.includes(base) || lower.includes(base)) {
      return 'Бұл құпия сөз тым жиі қолданылады. Жаңасын ойлап табыңыз';
    }
  }

  return null;
}

module.exports = { passwordStrengthError };
