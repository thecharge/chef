#!/usr/bin/env python3
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import dnf
import hawkey

from pprint import pprint

base = None

def get_sack():
    global base
    if base is None:
        base = dnf.Base()
        base.read_all_repos()
        base.fill_sack()
    return base.sack

def whatavailable(arg):
    sack = get_sack()
    subj = dnf.subject.Subject(arg)
    q = subj.get_best_query(sack)
    q = q.available()
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
    q = q.installed()
    pkgs = dnf.query.latest_limit_pkgs(q, 1)
    if not pkgs:
        sys.stdout.write('{} nil nil\n'.format(arg))
    else:
        pkg = pkgs.pop(0)
        sys.stdout.write('{} {}:{}-{} {}\n'.format(pkg.name, pkg.epoch, pkg.version, pkg.release, pkg.arch))

while 1:
    line = sys.stdin.readline()
    args = line.split()
    command = args.pop(0)
    if command == "whatprovides":
        whatprovides(args.pop(0))
    elif command == "whatinstalled":
        whatinstalled(args.pop(0))
    elif command == "whatavailable":
        whatavailable(args.pop(0))
    else:
        raise RuntimeError("bad command")
