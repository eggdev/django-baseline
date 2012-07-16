from subprocess import PIPE, Popen

class HerokuError(Exception): pass

def get_heroku_config():
    heroku_config = {}
    command = ['heroku', 'config']

    try:
        heroku = Popen(command, stdout=PIPE)
    except OSError, exc:
        if exc[0] != 2:
            raise

        raise HerokuError('Heroku config failed: {0}'.format(exc), ' '.join(command))

    output = heroku.communicate()[0]
    for line in output.splitlines():
        k, v = line.strip().split('=>', 1)
        heroku_config[k.strip()] = v.strip()

    return heroku_config

def set_heroku_config(**config):
    args = ['{0}={1}'.format(a, b) for a, b in config.items()]
    command = ['heroku', 'config:add'] + args

    try:
        heroku = Popen(command, stdout=PIPE, stderr=PIPE)
    except OSError, exc:
        if exc[0] != 2:
            raise

        raise HerokuError('Heroku config failed: {0}'.format(exc), ' '.join(command))

    stdout, stderr = heroku.communicate()
    status = heroku.wait()
    if status != 0:
        raise HerokuError('Heroku config failed: {0} (stdout: {1}, stderr: {2})'.format(' '.join(command), stdout, stderr), ' '.join(command))

def warn(message, color='yellow', name='Warning', prefix='', print_traceback=True):
    import sys
    from django.utils.termcolors import make_style

    red = make_style(fg=color, opts=('bold',))

    if print_traceback:
        import traceback
        traceback.print_exc()

    sys.stderr.write('{0}{1}: {2}\n'.format(prefix, red(name), message))
