echo "Setting pg folder"
mkdir -p /pg_data
#odoo
echo "Cloning odoo 13.0"
git clone git@github.com:odoo/odoo.git --depth 1 --branch 13.0 --single-branch odoo13.0
rm -rf .git/
rm .gitignore