# oracle-swizzin
Create a Swizzin box with Oracle Cloud Free Tier and Cloudflare domains

### Requirements:

* Oracle Cloud account (suggest using one stuck on the free tier i.e. 'un-upgraded')
* A domain name (or you can reconfigure to use a subdomain but domanins are really cheap)
* The domain should be loaded into your account on Cloudflare

You can use this with a cheap domain (e.g. .icu - $2/year) to set up a free an always-on box.

Do not start naked torrent connections with Oracle cloud! They will delete your account.

### Instructions:

* Ensure you have Terraform and the Oracle CLI installed
* Go to terraform_oci/ and rename `terraform.sample_tfvars` to `terraform.tfvars`
* Fill in `terraform.tfvars` with the values you want, including `compartment_ocid` as your compartment ID on oracle
* Run `rm ~/.oci/config && oci session authenticate --region us-ashburn-1` to refresh your oracle token. You have to do this every hour. Yes, it's stupid.
* Run `terraform init -upgrade && terraform apply -auto-approve` to execute the Terraform
* SSH into the server as Ubuntu, using the SSH key in `terraform_oci/id_rsa`, and run `sudo -i bash -c 'box install ombi plex'` to install ombi and plex (or whatever packages you want)
* For all your installed packages, run `sudo -i bash -c 'sudo systemctl enable packagename'` - see service management instructions here: https://swizzin.ltd/applications/nzbget

Within an hour, both LetsEncrypt and Cloudflare will update, and you should be able to connect to your server via secure HTTPS on your domain name! 
Change line 10 in `compute.tf` to use a subdomain 


Todo: 
* Automatically install the letsencrypt certificate into Plex - see here: https://hobo.house/2016/11/11/how-to-use-self-signed-ssl-certificates-for-plex-media-server/
