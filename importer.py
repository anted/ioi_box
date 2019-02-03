#!/usr/bin/env python3

import argparse
import logging
import hashlib
import importlib
import os
import subprocess
import sys


logger = logging.getLogger(__name__)


logging.basicConfig(level=logging.DEBUG)


CACHE_DIR = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'cache')


class DownloadError(Exception):
    pass


class ImportError(Exception):
    pass


class Downloader(object):
    WGET = '/usr/bin/wget'

    @staticmethod
    def check_wget():
        try:
            output = subprocess.check_output([Downloader.WGET, '--version'])
        except FileNotFoundError:
            logger.critical('Please install wget.')
        if output.startswith(b'GNU Wget'):
            logger.info('Found {}.'.format(output.splitlines()[0].strip()))
        else:
            logger.critical('Please install wget.')

    @staticmethod
    def sha1(filename):
        BUFFER_SIZE = 65536
        h = hashlib.sha1()
        with open(filename, 'rb') as handle:
            buffer = handle.read(BUFFER_SIZE)
            while len(buffer) > 0:
                h.update(buffer)
                buffer = handle.read(BUFFER_SIZE)
        logger.debug('{} {}'.format(filename, h.hexdigest()))
        return h.hexdigest()

    @staticmethod
    def download(url, destination, sha1=None):
        if os.path.isfile(destination) and Downloader.sha1(destination) == sha1:
            logger.info('File already exists and checksum matches. Skipping.')
            return 
        logger.info('Downloading {} to {}.'.format(url, destination))
        if subprocess.call([Downloader.WGET, '-c', '-O',destination, url]):
            logger.error('Download failed.')
            raise DownloadError('Download failed')
        if sha1 and Downloader.sha1(destination) != sha1:
            logger.error('Checksum mismatch.')
            raise DownloadError('Checksum mismatch.')


class ZipImporter(object):
    def __init__(self):
        pass

    def run_import_script(self, zip_path, contest_name):
        cmd = ['docker-compose', 'run',
                '-v', '{}:/contest.zip'.format(zip_path),
                'cms',
                '/scripts/cms_import_zip.sh', '/contest.zip', contest_name]
        if subprocess.check_call(cmd):
            raise ImportError('cms_import_zip.sh script failed.')
    
    def import_contest(self, config):
        if config.CONTEST_FORMAT != 'ZIP':
            logger.error('Invalid contest format {}.'.format(config.CONTEST_FORMAT))
            return False
        destination = os.path.join(CACHE_DIR, config.ZIP_FILENAME)
        Downloader.download(config.ZIP_URL, destination, config.ZIP_SHA1)
        self.run_import_script(destination, config.CONTEST_NAME)
        logger.info('Import successful!')


def main():
    parser = argparse.ArgumentParser(description='Adapt and import a contest.')
    parser.add_argument('path', metavar='contest.py', type=str, help='contest config file')
    args = parser.parse_args()
    logger.info('Importing contest {}'.format(args.path))
    dirname, filename = os.path.split(args.path)
    basename, extension = os.path.splitext(filename)
    if extension != ".py":
        logger.critical('Contest file must my a python module.')
    sys.path.append(dirname)
    module = importlib.import_module(basename)
    ZipImporter().import_contest(module.Config)


if __name__ == "__main__":
    main()
