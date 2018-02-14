%{--
  - Copyright 2016 SimplifyOps, Inc. (http://simplifyops.com)
  -
  - Licensed under the Apache License, Version 2.0 (the "License");
  - you may not use this file except in compliance with the License.
  - You may obtain a copy of the License at
  -
  -     http://www.apache.org/licenses/LICENSE-2.0
  -
  - Unless required by applicable law or agreed to in writing, software
  - distributed under the License is distributed on an "AS IS" BASIS,
  - WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  - See the License for the specific language governing permissions and
  - limitations under the License.
  --}%

<%@ page import="grails.util.Environment" %>
<html>
<head>
    <g:set var="rkey" value="${g.rkey()}" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta name="layout" content="base"/>
    <meta name="tabpage" content="jobs"/>
    <title><g:message code="gui.menu.Workflows"/> - <g:enc>${params.project ?: request.project}</g:enc></title>

    <asset:javascript src="util/yellowfade.js"/>
    <g:javascript library="pagehistory"/>
    <g:javascript library="prototype/effects"/>
    <asset:javascript src="menu/jobs.js"/>
    <g:if test="${grails.util.Environment.current==grails.util.Environment.DEVELOPMENT}">
        <asset:javascript src="menu/joboptionsTest.js"/>
        <asset:javascript src="menu/job-remote-optionsTest.js"/>
    </g:if>
    <g:embedJSON data="${projectNames ?: []}" id="projectNamesData"/>
    <g:embedJSON data="${nextScheduled ?: []}" id="nextScheduled"/>
    <g:embedJSON id="pageParams" data="${[project: params.project?:request.project,]}"/>
    <g:jsMessages code="Node,Node.plural,job.starting.execution,job.scheduling.execution,option.value.required,options.remote.dependency.missing.required,,option.default.button.title,option.default.button.text,option.select.choose.text"/>
    <g:jsMessages id="scmi18nmsgs"
                  code="scm.export.status.EXPORT_NEEDED.description,scm.export.status.CREATE_NEEDED.description,scm.export.status.CLEAN.description,scm.import.status.IMPORT_NEEDED.description"/>
    <g:jsMessages id="scmi18nmsgs2"
                  code="scm.import.status.IMPORT_NEEDED.description,scm.import.status.DELETE_NEEDED.description,scm.import.status.CLEAN.description,scm.import.status.REFRESH_NEEDED.description,scm.import.status.UNKNOWN.description"/>
    <g:jsMessages id="scmi18nmsgs3"
                  code="scm.export.status.EXPORT_NEEDED.display.text,scm.export.status.CREATE_NEEDED.display.text,scm.export.status.REFRESH_NEEDED.display.text,scm.export.status.DELETED.display.text,scm.export.status.CLEAN.display.text"/>
    <g:jsMessages id="scmi18nmsgs4"
                  code="scm.import.status.IMPORT_NEEDED.display.text,scm.import.status.REFRESH_NEEDED.display.text,scm.import.status.UNKNOWN.display.text,scm.import.status.CLEAN.display.text"/>
    <!--[if (gt IE 8)|!(IE)]><!--> <g:javascript library="ace/ace"/><!--<![endif]-->
    <script type="text/javascript">"use strict";

        /** knockout binding for activity */
        var pageActivity;


        //set box filterselections

        function _setFilterSuccess(data,name){
            if(data){
                var bfilters=data.filterpref;
                //reload page
                document.location=_genUrl(appLinks.menuJobs , bfilters[name] ? {filterName:bfilters[name]} : {});
            }
        }


        /** now running section update */
        function _pageUpdateNowRunning(count){
        }
        var lastRunExec=0;
        /**
         * Handle embedded content updates
         */
        function _updateBoxInfo(name,data){
            if(name==='events' && data.lastDate){
                histControl.setHiliteSince(data.lastDate);
            }
            if (name == 'nowrunning' && data.lastExecId && data.lastExecId != lastRunExec) {
                lastRunExec = data.lastExecId;
            }
        }

        /////////////
        // Job context detail popup code
        /////////////

        var doshow=false;
        var popvis=false;
        var lastHref;
        var targetLink;
        function popJobDetails(elem){
            if(doshow && $('jobIdDetailHolder')){
                new MenuController().showRelativeTo(elem,$('jobIdDetailHolder'));
                popvis=true;
                if(targetLink){
                    $(targetLink).removeClassName('glow');
                    targetLink=null;
                }
                $(elem).addClassName('glow');
                targetLink=elem;
            }
        }
        var motimer;
        var mltimer;
        function bubbleMouseover(evt){
            if(mltimer){
                clearTimeout(mltimer);
                mltimer=null;
            }
        }
        function jobLinkMouseover(elem,evt){
            if(mltimer){
                clearTimeout(mltimer);
                mltimer=null;
            }
            if(motimer){
                clearTimeout(motimer);
                motimer=null;
            }
            if(popvis && lastHref===elem.href){
                return;
            }
            var delay=1500;
            if(popvis){
                delay=0;
            }
            motimer=setTimeout(showJobDetails.curry(elem),delay);
        }
        function doMouseout(){
            if(popvis && $('jobIdDetailHolder')){
                popvis=false;
                Try.these(
                    function(){
                        jQuery('#jobIdDetailHolder').fadeOut('fast');
                    },
                    function(){$('jobIdDetailHolder').hide();}
                    );
            }
            if(targetLink){
                $(targetLink).removeClassName('glow');
                targetLink=null;
            }
        }
        function jobLinkMouseout(elem,evt){
            //hide job details
            if(motimer){
                clearTimeout(motimer);
                motimer=null;
            }
            doshow=false;
            mltimer=setTimeout(doMouseout,0);
        }
        function showJobDetails(elem){
            //get url
            var href=elem.href || elem.getAttribute('data-href');
            lastHref=href;
            doshow=true;
            //match is id
            var matchId = jQuery(elem).data('jobId');
            if(!matchId){
                return;
            }
            var viewdom=$('jobIdDetailHolder');
            var bcontent=$('jobIdDetailContent');
            if(viewdom){
                viewdom.parentNode.removeChild(viewdom);
                viewdom=null;
            }
            if(!viewdom){
                viewdom = $(document.createElement('div'));
                viewdom.addClassName('bubblewrap');
                viewdom.setAttribute('id','jobIdDetailHolder');
                viewdom.setAttribute('style','display:none;width:600px;height:250px;');

                Event.observe(viewdom,'click',function(evt){
                    evt.stopPropagation();
                },false);

                var btop = new Element('div');
                btop.addClassName('bubbletop');
                viewdom.appendChild(btop);
                bcontent = new Element('div');
                bcontent.addClassName('bubblecontent');
                bcontent.setAttribute('id','jobIdDetailContent');
                viewdom.appendChild(bcontent);
                document.body.appendChild(viewdom);
                Event.observe(viewdom,'mouseover',bubbleMouseover);
                Event.observe(viewdom,'mouseout',jobLinkMouseout.curry(viewdom));
            }
            bcontent.loading();
            var jobNodeFilters;
            jQuery.ajax({
                dataType:'json',
                url:_genUrl(appLinks.scheduledExecutionDetailFragmentAjax, {id: matchId}),
                success:function(data,status,xhr){
                    var params={};
                    if(data.job && data.job.doNodeDispatch) {
                        if (data.job.filter) {
                            params.filter = data.job.filter;
                        }
                    }else{
                        params.localNodeOnly=true;
                        params.emptyMode='localnode';
                    }
                    jobNodeFilters=initJobNodeFilters(params);
                }
            }).done(
                    function(){
                        jQuery('#jobIdDetailContent').load(_genUrl(appLinks.scheduledExecutionDetailFragment, {id: matchId}),
                                function(response,status,xhr){
                            if (status=='success') {
                                var wrapDiv = jQuery('#jobIdDetailHolder').find('.ko-wrap')[0];
                                if(wrapDiv) {
                                    ko.applyBindings(jobNodeFilters, wrapDiv);
                                }
                                popJobDetails(elem);
                                $('jobIdDetailContent').select('.apply_ace').each(function (t) {
                                    _applyAce(t);
                                });
                            }else{
                                clearHtml(bcontent);
                                viewdom.hide();
                            }
                        });
                    }
            );

        }

        function initJobIdLinks(){
            $$('.hover_show_job_info').each(function(e){
                Event.observe(e,'mouseover',jobLinkMouseover.curry(e));
                Event.observe(e,'mouseout',jobLinkMouseout.curry(e));
            });

            jQuery('.act_job_action_dropdown').click(function(){
                var id=jQuery(this).data('jobId');
                var el=jQuery(this).parent().find('.dropdown-menu');
                el.load(
                    _genUrl(appLinks.scheduledExecutionActionMenuFragment,{id:id})
                );
            });
        }
         function filterToggle(evt) {
            ['${enc(js:rkey)}filter','${enc(js:rkey)}filter-toggle'].each(Element.toggle);
        }
        function filterToggleSave(evt) {
            ['${enc(js:rkey)}filter','${enc(js:rkey)}fsave'].each(Element.show);
            ['${enc(js:rkey)}filter-toggle','${enc(js:rkey)}fsavebtn'].each(Element.hide);
        }
        function init(){
            <g:if test="${!(grailsApplication.config.rundeck?.gui?.enableJobHoverInfo in ['false',false])}">
            initJobIdLinks();
            </g:if>

            PageActionHandlers.registerHandler('job_delete_single',function(el){
                bulkeditor.activateActionForJob(bulkeditor.DELETE,el.data('jobId'));
            });
            PageActionHandlers.registerHandler('enable_job_execution_single',function(el){
                bulkeditor.activateActionForJob(bulkeditor.ENABLE_EXECUTION,el.data('jobId'));
            });
            PageActionHandlers.registerHandler('disable_job_execution_single',function(el){
                bulkeditor.activateActionForJob(bulkeditor.DISABLE_EXECUTION,el.data('jobId'));
            });
            PageActionHandlers.registerHandler('disable_job_schedule_single',function(el){
                bulkeditor.activateActionForJob(bulkeditor.DISABLE_SCHEDULE,el.data('jobId'));
            });
            PageActionHandlers.registerHandler('enable_job_schedule_single',function(el){
                bulkeditor.activateActionForJob(bulkeditor.ENABLE_SCHEDULE,el.data('jobId'));
            });

            PageActionHandlers.registerHandler('copy_other_project',function(el){
                jQuery('#jobid').val(el.data('jobId'));
                jQuery('#selectProject').modal();
            });


            Event.observe(document.body,'click',function(evt){
                //click outside of popup bubble hides it
                doMouseout();
            },false);
            Event.observe(document,'keydown',function(evt){
                //escape key hides popup bubble
                if(evt.keyCode===27 ){
                    doMouseout();
                }
                return true;
            },false);

            $$('.obs_filtertoggle').each(function(e) {
                Event.observe(e, 'click', filterToggle);
            });
            $$('.obs_filtersave').each(function(e) {
                Event.observe(e, 'click', filterToggleSave);
            });
        }






        var bulkeditor;
        jQuery(document).ready(function () {
            init();
            var pageParams = loadJsonData('pageParams');
            if (jQuery('#activity_section')) {
                pageActivity = new History(appLinks.reportsEventsAjax, appLinks.menuNowrunningAjax);
                ko.applyBindings(pageActivity, document.getElementById('activity_section'));
                setupActivityLinks('activity_section', pageActivity);
            }
            jQuery(document).on('click','.act_execute_job',function(evt){
                evt.preventDefault();
                var joboptsinput = new JobOptionsInput({
                    id: jQuery(this).data('jobId'),
                    project: pageParams.project,
                    contentId:'execDivContent',
                    displayId:'execDiv'
                });
                joboptsinput.loadExec();
            });
            $$('#wffilterform input').each(function(elem){
                if (elem.type === 'text') {
                    elem.observe('keypress',noenter);
                }
            });
            bulkeditor=new BulkEditor();
            initKoBind(null, {bulkeditor: bulkeditor});


            jQuery(document).on('click','#togglescm',function(evt){
                evt.preventDefault();
                jQuery.ajax({
                    dataType:'json',
                    method: "POST",
                    url:_genUrl(appLinks.togglescm),
                    params:nextScheduled,
                    success:function(data,status,xhr){
                        console.log(data);
                    }
                });
            });

            var nextScheduled = loadJsonData('nextScheduled');
            var nextSchedList="";
            for(var i=0; i< nextScheduled.length; i++){
                nextSchedList = nextSchedList+nextScheduled[i].id+",";
            }

            jQuery.ajax({
                dataType:'json',
                method: "POST",
                url:_genUrl(appLinks.scmjobs, {nextScheduled:nextSchedList}),
                params:nextScheduled,
                success:function(data,status,xhr){
                    bulkeditor.scmExportEnabled(data.scmExportEnabled);
                    bulkeditor.scmStatus(data.scmStatus);
                    bulkeditor.scmExportStatus(data.scmExportStatus);
                    bulkeditor.scmExportActions(data.scmExportActions);
                    bulkeditor.scmExportRenamed(data.scmExportRenamed);

                    bulkeditor.scmImportEnabled(data.scmImportEnabled);
                    bulkeditor.scmImportJobStatus(data.scmImportJobStatus);
                    bulkeditor.scmImportStatus(data.scmImportStatus);
                    bulkeditor.scmImportActions(data.scmImportActions);
                }
            });
        });


    </script>

    <asset:javascript src="util/yellowfade.js"/>
    <style type="text/css">
    .error{
        color:red;
    }

        #histcontent table{
            width:100%;
        }
    </style>
</head>
<body>


<g:if test="${flash.bulkJobResult?.errors}">
    <div class="alert alert-dismissable alert-warning">
        <a class="close" data-dismiss="alert" href="#" aria-hidden="true">&times;</a>
        <ul>
            <g:if test="${flash.bulkJobResult.errors instanceof org.springframework.validation.Errors}">
                <g:renderErrors bean="${flash.bulkJobResult.errors}" as="list"/>
            </g:if>
            <g:else>
                <g:each in="${flash.bulkJobResult.errors*.message}" var="message">
                    <li><g:autoLink>${message}</g:autoLink></li>
                </g:each>
            </g:else>
        </ul>
    </div>
</g:if>
<g:if test="${flash.bulkJobResult?.success}">
    <div class="alert alert-dismissable alert-info">
        <a class="close" data-dismiss="alert" href="#" aria-hidden="true">&times;</a>
        <ul>
        <g:each in="${flash.bulkJobResult.success*.message}" var="message">
            <li><g:autoLink>${message}</g:autoLink></li>
        </g:each>
        </ul>
    </div>
</g:if>
<div class="runbox primary jobs" id="indexMain">
    <div id="error" class="alert alert-danger" style="display:none;"></div>
    <g:render template="workflowsFull" model="${[jobExpandLevel:jobExpandLevel,jobgroups:jobgroups,wasfiltered:wasfiltered?true:false, clusterMap: clusterMap,nextExecutions:nextExecutions,jobauthorizations:jobauthorizations,authMap:authMap,nowrunningtotal:nowrunningtotal,max:max,offset:offset,paginateParams:paginateParams,sortEnabled:true,rkey:rkey, clusterModeEnabled:clusterModeEnabled]}"/>
</div>

<div class="modal fade" id="execDiv" role="dialog" aria-labelledby="execOptionsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h4 class="modal-title" id="execOptionsModalLabel"><g:message code="job.execute.action.button"/></h4>
            </div>

            <div class="" id="execDivContent">


            </div>
</div>
</div>
</div>

<g:render template="/menu/copyModal"
          model="[projectNames: projectNames]"/>

<div class="row row-space" id="activity_section">
    <div class="col-sm-12 ">
        <h4 class="text-muted "><g:message code="page.section.Activity.for.jobs" /></h4>
        <g:render template="/reports/activityLinks"
                  model="[filter: [projFilter: params.project ?: request.project, jobIdFilter: '!null',], knockoutBinding: true, showTitle:true]"/>
    </div>
</div>
</body>
</html>
