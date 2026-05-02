import json, os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

EN_KEYS = {
    'no_intermediaries': 'No intermediaries.\n0% commissions.',
    'buy_sell_no_fees': 'Buy and sell with no commissions.',
    'search_to_notary': 'From search to notary\nin safe steps.',
    'eliminate_uncertainty': 'Eliminate uncertainty.',
    'tagline': 'Real estate made easy between individuals',
    'access_secure_panel': 'Access your secure InmuFacil dashboard.',
    'guarantee_label': 'INMUFACIL GUARANTEE',
    'guarantee_title': 'Sell with confidence',
    'p2p_verified_title': 'Buy securely',
    'continue_without_account': 'Continue without registering \u2192',
    'register_link': 'Sign up',
    'account_created': 'Account created. Please sign in.',
    'no_fees': 'NO COMMISSIONS',
    'create_account': 'Create your account',
    'join_p2p': 'Join the most secure P2P network in real estate.',
    'min_3_chars': 'Minimum 3 characters',
    'email_label_short': 'Email address',
    'password_label_short': 'Password',
    'min_8_chars': 'Minimum 8 characters',
    'generate_password': 'Generate secure password',
    'confirm_password': 'Confirm password',
    'confirm_password_hint_register': 'Repeat your password',
    'accept_prefix': 'I accept the ',
    'terms_conditions': 'Terms and Conditions',
    'privacy_policy': 'Privacy Policy',
    'already_have_account': 'Already have an account? ',
}

FR_KEYS = {
    'no_intermediaries': "Sans interm\u00e9diaires.\n0% de commissions.",
    'buy_sell_no_fees': "Achetez et vendez sans commissions.",
    'search_to_notary': "De la recherche au notaire\nen toute s\u00e9curit\u00e9.",
    'eliminate_uncertainty': "Eliminez l'incertitude.",
    'tagline': "L'immobilier facile entre particuliers",
    'access_secure_panel': "Acc\u00e9dez \u00e0 votre espace s\u00e9curis\u00e9 InmuFacil.",
    'guarantee_label': 'GARANTIE INMUFACIL',
    'guarantee_title': "Vendez en toute tranquillit\u00e9",
    'p2p_verified_title': "Achetez en s\u00e9curit\u00e9",
    'continue_without_account': "Continuer sans inscription \u2192",
    'register_link': "S'inscrire",
    'account_created': "Compte cr\u00e9\u00e9. Veuillez vous connecter.",
    'no_fees': 'SANS COMMISSIONS',
    'create_account': "Cr\u00e9ez votre compte",
    'join_p2p': "Rejoignez le r\u00e9seau P2P le plus s\u00fbr de l'immobilier.",
    'min_3_chars': "Minimum 3 caract\u00e8res",
    'email_label_short': 'Adresse e-mail',
    'password_label_short': 'Mot de passe',
    'min_8_chars': "Minimum 8 caract\u00e8res",
    'generate_password': "G\u00e9n\u00e9rer un mot de passe s\u00e9curis\u00e9",
    'confirm_password': 'Confirmer le mot de passe',
    'confirm_password_hint_register': "R\u00e9p\u00e9tez votre mot de passe",
    'accept_prefix': "J'accepte les ",
    'terms_conditions': "Conditions g\u00e9n\u00e9rales",
    'privacy_policy': "Politique de confidentialit\u00e9",
    'already_have_account': "D\u00e9j\u00e0 un compte ? ",
}

CA_KEYS = {
    'no_intermediaries': "Sense intermediaris.\n0% comissions.",
    'buy_sell_no_fees': "Compra i ven sense comissions.",
    'search_to_notary': "De la cerca a la notaria\nen passos segurs.",
    'eliminate_uncertainty': "Elimina la incertesa.",
    'tagline': "Immobles f\u00e0cil entre particulars",
    'access_secure_panel': "Accedeix al teu panell segur d'InmuFacil.",
    'guarantee_label': 'GARANTIA INMUFACIL',
    'guarantee_title': "La teva venda tranquil\u00b7la",
    'p2p_verified_title': 'La teva compra segura',
    'continue_without_account': "Continuar sense registrar-se \u2192",
    'register_link': "Registra't",
    'account_created': "Compte creat. Si us plau, inicia sessi\u00f3.",
    'no_fees': 'SENSE COMISSIONS',
    'create_account': 'Crea el teu compte',
    'join_p2p': "Uneix-te a la xarxa P2P m\u00e9s segura del sector immobiliari.",
    'min_3_chars': "M\u00ednim 3 car\u00e0cters",
    'email_label_short': "Correu electr\u00f2nic",
    'password_label_short': 'Contrasenya',
    'min_8_chars': "M\u00ednim 8 car\u00e0cters",
    'generate_password': 'Generar contrasenya segura',
    'confirm_password': 'Confirmar contrasenya',
    'confirm_password_hint_register': 'Repeteix la contrasenya',
    'accept_prefix': 'Accepto els ',
    'terms_conditions': 'Termes i Condicions',
    'privacy_policy': 'Pol\u00edtica de Privacitat',
    'already_have_account': 'Ja tens compte? ',
}

EU_KEYS = {
    'no_intermediaries': "Bitartekorik gabe.\n%0 komisioak.",
    'buy_sell_no_fees': "Erosi eta saldu komisiorik gabe.",
    'search_to_notary': "Bilaketarik notariora\nurrats seguruetan.",
    'eliminate_uncertainty': "Ezabatu ziurgabetasuna.",
    'tagline': 'Etxebizitzak erraz partikularren artean',
    'access_secure_panel': 'Sartu zure InmuFacil panel segurura.',
    'guarantee_label': 'INMUFACIL BERMEA',
    'guarantee_title': 'Zure salmenta lasai',
    'p2p_verified_title': 'Zure erosketa segurua',
    'continue_without_account': "Jarraitu erregistratu gabe \u2192",
    'register_link': 'Erregistratu',
    'account_created': 'Kontua sortua. Mesedez, hasi saioa.',
    'no_fees': 'KOMISIORIK GABE',
    'create_account': 'Sortu zure kontua',
    'join_p2p': 'Batu higiezinen sektoreko P2P sare seguruenera.',
    'min_3_chars': 'Gutxienez 3 karaktere',
    'email_label_short': 'Helbide elektronikoa',
    'password_label_short': 'Pasahitza',
    'min_8_chars': 'Gutxienez 8 karaktere',
    'generate_password': 'Pasahitz segurua sortu',
    'confirm_password': 'Pasahitza berretsi',
    'confirm_password_hint_register': 'Errepikatu pasahitza',
    'accept_prefix': 'Onartzen ditut ',
    'terms_conditions': 'Baldintzak',
    'privacy_policy': 'Pribatutasun Politika',
    'already_have_account': 'Dagoeneko kontua duzu? ',
}

GL_KEYS = {
    'no_intermediaries': "Sen intermediarios.\n0% comisi\u00f3ns.",
    'buy_sell_no_fees': "Compra e vende sen comisi\u00f3ns.",
    'search_to_notary': "Da busca ao notario\nen pasos seguros.",
    'eliminate_uncertainty': "Elimina a incerteza.",
    'tagline': "Inmobles f\u00e1cil entre particulares",
    'access_secure_panel': "Accede ao teu panel seguro de InmuFacil.",
    'guarantee_label': 'GARANT\u00cdA INMUFACIL',
    'guarantee_title': 'A t\u00faa venda tranquila',
    'p2p_verified_title': 'A t\u00faa compra segura',
    'continue_without_account': "Continuar sen rexistrarse \u2192",
    'register_link': "Rex\u00edstrate",
    'account_created': "Conta creada. Por favor, inicia sesi\u00f3n.",
    'no_fees': "SEN COMISI\u00d3NS",
    'create_account': "Crea a t\u00faa conta",
    'join_p2p': "Unete \u00e1 rede P2P m\u00e1is segura do sector inmobiliario.",
    'min_3_chars': "M\u00ednimo 3 caracteres",
    'email_label_short': "Correo electr\u00f3nico",
    'password_label_short': 'Contrasinal',
    'min_8_chars': "M\u00ednimo 8 caracteres",
    'generate_password': 'Xerar contrasinal seguro',
    'confirm_password': 'Confirmar contrasinal',
    'confirm_password_hint_register': 'Repite o contrasinal',
    'accept_prefix': 'Acepto os ',
    'terms_conditions': "Termos e Condici\u00f3ns",
    'privacy_policy': 'Pol\u00edtica de Privacidade',
    'already_have_account': 'Xa tes conta? ',
}

file_keys = {
    'en-US.json': EN_KEYS,
    'en-GB.json': EN_KEYS,
    'en-CA.json': EN_KEYS,
    'fr-FR.json': FR_KEYS,
    'fr-CA.json': FR_KEYS,
    'ca-ES.json': CA_KEYS,
    'eu-ES.json': EU_KEYS,
    'gl-ES.json': GL_KEYS,
}

for filename, keys in file_keys.items():
    with open(filename, 'r', encoding='utf-8') as f:
        data = json.load(f)

    added = 0
    if 'auth' in data:
        for k, v in keys.items():
            if k not in data['auth']:
                data['auth'][k] = v
                added += 1

    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

    print(f'{filename}: added {added} new auth keys')

print('Done!')
