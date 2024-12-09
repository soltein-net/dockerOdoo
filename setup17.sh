echo "Setting pg folder"
mkdir -p /pg_data
#odoo
echo "Cloning odoo 17.0"
git clone git@github.com:odoo/odoo.git --depth 1 --branch 17.0 --single-branch odoo17.0
rm -rf .git/
rm .gitignore
