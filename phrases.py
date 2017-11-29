import mongo

with open('phrases.list','r') as f:
    a = f.read().strip()

a = a.split('\n')
b = []

for line in a:
    if line.count('|') > 0:
        b.append(line)
    else:
        b[-1] += '\n' + line

b = [line for line in b if line.count('|') == 1]
b = [tuple(x.split('|')) for x in b]

for x in b:
    clean = lambda x: x.strip().lower()
    defnName, meaning = x[0], x[1]

    defnName = clean(defnName)
    q = mongo.findDefn(defnName)
    if q:
        pass # don't update
        # mongo.updateDefn(defnName, meaning)
        # print(defnName + ' updated.')
    else:
        mongo.addDefn(defnName, meaning)
        print(defnName + ' added.')

# with open('newphrases.list','w') as f:
#     for line in b:
#         f.write(line+'\n')