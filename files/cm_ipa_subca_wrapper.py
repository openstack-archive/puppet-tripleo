#!/usr/bin/python
from __future__ import print_function
try:
    import ConfigParser as configparser
except ImportError:
    import configparser
import os
import sys
import subprocess

CM_SUBMIT_STATUS_ISSUED = 0
CM_SUBMIT_STATUS_UNCONFIGURED = 4

def main():
    if len(sys.argv) < 3:
        return CM_SUBMIT_STATUS_UNCONFIGURED
    sub_ca = sys.argv[1]
    wrapped_command = sys.argv[2:]

    operation = os.environ.get('CERTMONGER_OPERATION')
    os.environ['CERTMONGER_CA_NICKNAME'] = 'IPA'

    if operation == 'FETCH-ROOTS' and sub_ca.lower() != 'ipa':
        config = configparser.ConfigParser()
        try:
            with open('/etc/ipa/default.conf') as fp:
                config.readfp(fp)
        except:
            return CM_SUBMIT_STATUS_UNCONFIGURED
        host = config.get('global', 'host')
        realm = config.get('global', 'realm')
        if host is None or realm is None:
            return CM_SUBMIT_STATUS_UNCONFIGURED
        principal = 'host/{}@{}'.format(host, realm)
        os.environ['KRB5CCNAME'] = '/tmp/krb5cc_cm_ipa_subca_wrapper'
        try:
            subprocess.check_call([
                '/usr/bin/kinit', '-k', principal
            ])
        except:
            return CM_SUBMIT_STATUS_UNCONFIGURED

        try:
            data = subprocess.check_output([
                '/usr/bin/ipa', 'ca-show', sub_ca
            ])
        except:
            return CM_SUBMIT_STATUS_ISSUED

        config = {}
        for line in data.split('\n'):
            line = line.strip()
            try:
                key, value = line.split(': ')
            except:
                continue
            config[key] = value

        if config.get('Name').lower() != sub_ca.lower():
            return CM_SUBMIT_STATUS_ISSUED

        print(realm, sub_ca, 'CA')
        print('-----BEGIN CERTIFICATE-----')
        certificate = config['Certificate']
        for i in range((len(certificate)/64) + 1):
            print(certificate[i*64:(i+1)*64])
        print('-----END CERTIFICATE-----')
        sys.stdout.flush()
    else:
        os.environ['CERTMONGER_CA_ISSUER'] = sub_ca

    os.execl(wrapped_command[0], *wrapped_command)

if __name__ == '__main__':
    main()
