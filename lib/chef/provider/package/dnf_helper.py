#!/usr/bin/env python3
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import dnf
import hawkey
import signal
import os

from pprint import pprint

base = None

def get_sack():
    global base
    if base is None:
        base = dnf.Base()
        base.read_all_repos()
        base.fill_sack()
    return base.sack

def flushcache():
    global base
    base = None

def whatavailable(arg):
    sack = get_sack()
    subj = dnf.subject.Subject(arg)

    q = subj.get_best_query(sack)
    q_kwargs = {}

    # handle arch
    poss = dnf.util.first(subj.subj.nevra_possibilities_real(sack, allow_globs=True))
    if not poss:
      sys.stdout.write('{} nil nil\n'.format(arg))
      return

    if poss.arch:
      q_kwargs['arch'] = [ 'noarch', poss.arch ]
    else:
      q_kwargs['arch'] = [ 'noarch', hawkey.detect_arch() ]

    q = q.available()

    q = q.filter(**q_kwargs)

    pkgs = dnf.query.latest_limit_pkgs(q, 1)
    if not pkgs:
        sys.stdout.write('{} nil nil\n'.format(arg))
    else:
        pkg = pkgs.pop(0)
        sys.stdout.write('{} {}:{}-{} {}\n'.format(pkg.name, pkg.epoch, pkg.version, pkg.release, pkg.arch))

def whatinstalled(arg):
    sack = get_sack()
    subj = dnf.subject.Subject(arg)

    q = subj.get_best_query(sack)
    q_kwargs = {}

    # handle arch
    poss = dnf.util.first(subj.subj.nevra_possibilities_real(sack, allow_globs=True))
    if not poss:
      sys.stdout.write('{} nil nil\n'.format(arg))
      return

    if poss.arch:
      q_kwargs['arch'] = [ 'noarch', poss.arch ]
    else:
      q_kwargs['arch'] = [ 'noarch', hawkey.detect_arch() ]

    q = q.installed()

    q = q.filter(**q_kwargs)

    pkgs = dnf.query.latest_limit_pkgs(q, 1)
    if not pkgs:
        sys.stdout.write('{} nil nil\n'.format(arg))
    else:
        pkg = pkgs.pop(0)
        sys.stdout.write('{} {}:{}-{} {}\n'.format(pkg.name, pkg.epoch, pkg.version, pkg.release, pkg.arch))

def exit_handler(signal, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, exit_handler)
signal.signal(signal.SIGHUP, exit_handler)
signal.signal(signal.SIGPIPE, exit_handler)
signal.signal(signal.SIGCHLD, exit_handler)

while 1:
    ppid = os.getppid()
    if ppid == 1:
        sys.exit(0)
    line = sys.stdin.readline()
    args = line.split()
    if args:
        command = args.pop(0)
        if command == "whatinstalled":
            whatinstalled(args.pop(0))
        elif command == "whatavailable":
            whatavailable(args.pop(0))
        elif command == "flushcache":
            flushcache()
        else:
            raise RuntimeError("bad command")
    else:
        sys.exit(0)
