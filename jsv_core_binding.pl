#!/usr/bin/perl

# This perl port was originally written by Arnau Bria and slightly modified by Pablo Escobar. Here is the original by Arnau: http://gridengine.org/pipermail/users/2013-April/005866.html The only important change is changing from binding_strategy:linear to binding_strategy:linear_automatic

# Perl JSV has better performance than the bash version.
# To get the best performance be sure to run the jsv in the server side (qconf -mconf >> jsv_url)
# https://blogs.oracle.com/templedf/entry/performance_considerations_for_jsv_scripts

use strict;
use warnings;
no warnings qw/uninitialized/;

use Env qw(SGE_ROOT);
use lib "$SGE_ROOT/util/resources/jsv";
#use JSV qw( :DEFAULT jsv_send_env jsv_log_info );
use JSV qw( :DEFAULT jsv_sub_is_param jsv_sub_add_param jsv_sub_get_param jsv_send_env jsv_log_info jsv_is_param jsv_get_param jsv_log_warning jsv_log_error);



# my $sge_root = $ENV{SGE_ROOT};
# my $sge_arch = qx{$sge_root/util/arch};

jsv_on_start(sub {
   jsv_send_env();
});


jsv_on_verify(sub {
   my %params = jsv_get_param_hash();
   
   # print all params for debugging
   # this only works when running jsv at client side
   # jsv client side: $> qsub -jsv /path/to/jsv.pl submit_script.sh
   # jsv_log_info(%params);
   
   # this functions can be used to add info to the master logfile
   # it only works when running jsv at server side
   # jsv server side: qconf -mconf >> jsv_url
   # jsv_log_warning('this is a test message to master log');
   # jsv_log_error('this is a test error message to log');

   # You must ask for a queue
   #	if (!(exists $params{q_hard})) {
   #		# this message is only printed when running jvs in client side
   #		jsv_log_info ('No queue specified, your job will be submitted to short queue');
   #		jsv_sub_add_param('q_hard','short');
   #	}

   #	 You must ask for  time limit
   #	if (!(exists $params{l_hard}{h_rt})) {
   #		jsv_sub_add_param('l_hard','h_rt','6:00:00');
   #		# this message is only printed when running jvs in client side
   #		jsv_log_info ('No time requested, default is 6h');
   #	}



   # Binding strategy: we don't want user to specify it. Reject job if someone ask for some stragety
	if (exists $params{binding_strategy}) {
		#jsv_log_info ('Are you sure you want to specify binding startegy?');
		jsv_reject ('Are you sure you want to specify binding strategy? Contact xxx@mail.com');
		return;
	}else{
	# If not specified we will add it:
	# No PE:
		#if (!(exists $params{pe_name})) {
	  	if (!(exists $params{pe_name}) || (($params{pe_name} eq 'smp') && ($params{pe_min} eq '1')) ) {
                	# -------------------------------------------
                	# in case no parallel environment was chosen
                	# add a default request of one processor core
                	# -------------------------------------------

                	# set the binding strategy to linear (without given start point: linear)
			jsv_sub_add_param('binding_type','set');
			jsv_sub_add_param('binding_strategy','linear_automatic');
			jsv_sub_add_param('binding_amount','1');
   			# this message is only printed when running jvs in client side
			jsv_log_info ('Core binding added');
		}elsif ($params{pe_name} eq 'smp'){
			# This is a SMP job. First, add Reservation:
			jsv_sub_add_param('R','y');
   			# this message is only printed when running jvs in client side
			jsv_log_info ('Parallel Job needs a reservation');
	                # --------------------------------------------
        	        # "smp" was requested but no core binding
        	        # -> set linear allocation with pe max slots
        	        # --------------------------------------------

        	        # max amount of requested slots (smp)
			jsv_sub_add_param('binding_type','set');
			jsv_sub_add_param('binding_amount',"$params{pe_max}");
			jsv_sub_add_param('binding_strategy','linear_automatic');
		}elsif ($params{pe_name} eq 'ompi'){
			jsv_sub_add_param('R','y');
   			# this message is only printed when running jvs in client side
			jsv_log_info ('Parallel Job needs a reservation');
	                # --------------------------------------------
        	        # "ompi" was requested but no core binding
        	        # -> set linear allocation with pe max slots
        	        # --------------------------------------------

        	        # max amount of requested slots (smp)
			#jsv_sub_add_param('binding_type','set');
			#jsv_sub_add_param('binding_amount',"$params{pe_max}");
			#jsv_sub_add_param('binding_strategy','linear');
		}	
	} 

   
      jsv_accept('Job is accepted');
      return;


}); 

jsv_main();

