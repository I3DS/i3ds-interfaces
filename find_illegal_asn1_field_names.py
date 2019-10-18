import sys

bad_words = {'active', 'adding', 'all', 'alternative', 'and', 'any', 'as', 'atleast', 'axioms', 'block', 'call', 'channel', 'comment', 'connect', 'connection', 'constant', 'constants', 'create', 'dcl', 'decision', 'default', 'else', 'endalternative', 'endblock', 'endchannel', 'endconnection', 'enddecision', 'endgenerator', 'endmacro', 'endnewtype', 'endoperator', 'endpackage', 'endprocedure', 'endprocess', 'endrefinement', 'endselect', 'endservice', 'endstate', 'endsubstructure', 'endsyntype', 'endsystem', 'env', 'error', 'export', 'exported', 'external', 'fi', 'finalized', 'for', 'fpar', 'from', 'gate', 'generator', 'if', 'import', 'imported', 'in', 'inherits', 'input', 'interface', 'join', 'literal', 'literals', 'macro', 'macrodefinition', 'macroid', 'map', 'mod', 'nameclass', 'newtype', 'nextstate', 'nodelay', 'noequality', 'none', 'not', 'now', 'offspring', 'operator', 'operators', 'or', 'ordering', 'out', 'output', 'package', 'parent', 'priority', 'procedure', 'process', 'provided', 'redefined', 'referenced', 'refinement', 'rem', 'remote', 'reset', 'return', 'returns', 'revealed', 'reverse', 'save', 'select', 'self', 'sender', 'service', 'set', 'signal', 'signallist', 'signalroute', 'signalset', 'spelling', 'start', 'state', 'stop', 'struct', 'substructure', 'synonym', 'syntype', 'system', 'task', 'then', 'this', 'to', 'type', 'use', 'via', 'view', 'viewed', 'virtual', 'with', 'xor', 'end', 'i', 'j', 'auto', 'const', 'abstract', 'activate', 'and', 'assume', 'automaton', 'bool', 'case', 'char', 'clock', 'const', 'default', 'div', 'do', 'else', 'elsif', 'emit', 'end', 'enum', 'every', 'false', 'fby', 'final', 'flatten', 'fold', 'foldi', 'foldw', 'foldwi', 'function', 'guarantee', 'group', 'if', 'imported', 'initial', 'int', 'is', 'last', 'let', 'make', 'map', 'mapfold', 'mapi', 'mapw', 'mapwi', 'match', 'merge', 'mod', 'node', 'not', 'numeric', 'of', 'onreset', 'open', 'or', 'package', 'parameter', 'pre', 'private', 'probe', 'public', 'real', 'restart', 'resume', 'returns', 'reverse', 'sensor', 'sig', 'specialize', 'state', 'synchro', 'tel', 'then', 'times', 'transpose', 'true', 'type', 'unless', 'until', 'var', 'when', 'where', 'with', 'xor', 'open', 'close', 'flag', 'device', 'range', 'name', 'definitions', 'application', 'automatic', 'implicit', 'explicit', 'tags', 'begin', 'imports', 'exports', 'from', 'all', 'choice', 'sequence', 'set', 'of', 'end', 'optional', 'integer', 'real', 'octet', 'string', 'boolean', 'true', 'false', 'asciistring', 'numberstring', 'visiblestring', 'printablestring', 'utf8string', 'enumerated', 'semi', 'lparen', 'rparen', 'lbracket', 'rbracket', 'block_end', 'block_begin', 'def', 'name', 'comma', 'intvalue', 'realvalue', 'default', 'size', 'dotdot', 'dotdotdot', 'with', 'components', 'mantissa', 'base', 'exponent'}

if len(sys.argv) < 2:
    print('Usage: ' + sys.argv[0] + ' <filename>')

file_name = sys.argv[1]
with open(file_name) as f:
    line_number = 0
    for line in f:
        line_number += 1
        for word in line.split():
            if word.startswith('--'):
                break
            if word in bad_words:
                print (file_name + ':' + str(line_number) + ' Found illegal word "' + word + '"')

