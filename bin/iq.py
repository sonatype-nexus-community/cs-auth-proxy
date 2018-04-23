import json
import sys

def parseJSON():
    return json.load(sys.stdin)

# stdin is json response from membershipMapping/global/global/ 
def addMemberToAdminRole():
    userid = sys.argv[1]
    name = sys.argv[2]
    email = sys.argv[3]
    new_member = { 
        "type": "USER",
        "internalName": userid,
        "displayName": name,
        "email": email,
        "realm": "IQ Server"
    }

    resp = parseJSON()
    role = roleByName(resp['membersByRole'],"System Administrator")
    role['membersByOwner'][0]['members'].append(new_member)
    return json.dumps(role['membersByOwner'][0]['members'])

# devRoleId() - return id for the ROOT_ORG "Developer" role
# stdin is json response from sidebar/organization/ROOT_ORGANIZATION_ID/details
def devRoleId():
    resp = parseJSON()
    role = roleByName(resp['roles']['membersByRole'],"Developer")
    return role['roleId']


# adminRoleId() - return id for global "System Administrator" role
# stdin is json response from membershipMapping/global/global/ 
def adminRoleId():
    resp = parseJSON()
    role = roleByName(resp['membersByRole'],"System Administrator")
    return role['roleId']

def roleByName(membersByRole, name):
    i = findByValue(membersByRole, 'roleName', name)
    if i < 0:
        raise IndexError("no matching name in membersByRole", name)
    return membersByRole[i]
    
def findByValue(lst, key, value):
    for i, dic in enumerate(lst):
        if dic[key] == value:
            return i
    return -1

