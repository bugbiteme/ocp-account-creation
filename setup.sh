# defualt user.htpasswd file uses redhat123! for both admin and developer
# Run the commands outlined in README.md to set new users and passwords

# Create the OpenShift Secret
oc create secret generic htpass-secret \
  --from-file=htpasswd=users.htpasswd \
  -n openshift-config

# Configure the OpenShift OAuth custom resource to use the new Secret as an identity provider
oc apply -f htpasswd-provider.yaml

# Grant User Permissions (RBAC)
oc adm policy add-cluster-role-to-user cluster-admin admin
oc adm policy add-cluster-role-to-user self-provisioner developer

