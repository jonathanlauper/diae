/**** 
 * Use this place to implement client-side computed fields
 * Contributors(s) : S. Sire
 ***/
(function () {

  /*****************************************************************************\
  |                                                                             |
  |  'c-dellogbook' command object                                              |
  |                                                                             |
  |   Special command to delete a log book entry in a table                     |
  |                                                                             |
  |   TODO: move to extension.js ?                                              |
  \*****************************************************************************/
  (function () {
    function DeleteCommand ( identifier, node ) {
      this.spec = $(node);
      this.spec.bind('click', $.proxy(this, 'execute'));
    }
    DeleteCommand.prototype = {

      successCb : function (response, status, xhr) {
        var l = this.anchor.text();
        if (xhr.status === 200) { // end of transactional protocol
          alert($('success > message', xhr.responseXML).text());
          this.anchor.remove();
        } else {
          this.spec.trigger('axel-network-error', { xhr : xhr, status : "unexpected" });
        }
      },

      errorCb : function (xhr, status, e) {
        this.spec.trigger('axel-network-error', { xhr : xhr, status : status, e : e });
      },

      execute : function (ev) {
        var ask = this.spec.attr('data-confirm'),
            id, url;
        this.anchor = $(ev.target).parent().parent(); // <i> inside <td> inside <tr>
        id = this.anchor.attr('data-id');
        if (id) {
          url = this.spec.attr('data-controller');
          if (ask) {
            proceed = confirm(ask);
          }
          if (proceed && url) {
            $.ajax({
              url : url + '/' + id,
              type : 'delete',
              // type : 'post',
              // data : { '_delete' : 1 },
              cache : false,
              timeout : 20000,
              success : $.proxy(this, "successCb"),
              error : $.proxy(this, "errorCb")
            });
          }
        }
      }
    };
    $axel.command.register('c-dellogbook', DeleteCommand, { check : false });
  }());

  // ********************************************************
  //        Coach Match Integration
  //
  // DEPRECATED : will be moved to an 'match' command 
  //              (in extensions.js)
  //
  // TODO : manage errors 
  // ********************************************************

  // FIXME: read form action from returned payload (?)
  function open_suggestion ( data, status, xhr ) {
    var payload = xhr.responseText;
    $('#ct-suggest-form > input[name="data"]').val(payload);
    $('#ct-suggest-submit').click();
  }

  // Posts required coach profile to case tracker and retrieve XML payload 
  // for posting to 3rd Coach Match coach suggestion tunnel (see open_suggestion)
  function start_suggestion() {
    var payload = $axel('#c-editor-coaching-assignment').xml();
    $.ajax({
      url : window.location.href + '/match',
      type : 'post',
      async : false,
      data : payload,
      dataType : 'xml',
      cache : false,
      timeout : 50000,
      contentType : "application/xml; charset=UTF-8",
      success : open_suggestion
    });
    // return true;
  }

  function install_coachmatch() {
    $('#ct-suggest-button').click(start_suggestion);
  }
  
  // ********************************************************
  //          Coaching plan computed fields
  // ********************************************************

  // Updates all computed values in coaching plan
  function update_cplan() {
var budget = $axel('#x-freq-Budget'),
    hr = $axel('#x-freq-CoachingHourlyRate').peek('CoachingHourlyRate'),
    tasks = $axel('#x-freq-Tasks').vector('NbOfHours').product(hr).sum(),
    other = $axel('#x-freq-OtherExpenses').vector('Amount').sum(),
    spending = tasks + other,
    funding = $axel('#x-freq-FundingSources').vector('RequestedAmount').sum(),
    balance = Math.round((funding - spending)*100)/100;
    budget.poke('TotalTasks', tasks);
    budget.poke('TotalOtherExpenses', other);
    budget.poke('TotalBudget', spending);
    budget.poke('TotalRequested', funding);
    budget.poke('BudgetBalance', { '#val' : balance, 'color' : balance >= 0 ? 'green' : 'red' });
  }

  // To be called each time the editor is generated
  function install_cplan() {
    $('#x-freq-Budget')
      .bind('axel-update', update_cplan)
      .bind('axel-add', update_cplan)
      .bind('axel-remove', update_cplan);
  }

  // ********************************************************
  //          Coach contracting computed fields
  // ********************************************************

  // Computes and updates a Balance row in coach contracting then recomputes the totals
  function update_ccontracting(ev) {
    var row = $axel($(ev.target).closest('.x-cc-FundingSource')), balance;
    balance = row.peek('ApprovedAmount') - row.peek('RequestedAmount');
    row.poke('Balance', { '#val' : balance, 'color' : balance >= 0 ? 'green' : 'red' });
    recompute_ccontracting();
  }

  // Computes and updates totals in coach contracting
  function recompute_ccontracting() {
    var model = $axel('#x-cc-FundingSources'), 
        approved = model.vector('ApprovedAmount').sum(),
        requested = model.peek('TotalRequested'),
        balance = approved - requested;
    model.poke('TotalApproved', approved);
    model.poke('ApprovedBalance', { '#val' : balance, 'color' : balance >= 0 ? 'green' : 'red' });
  }

  // To be called each time the editor is generated
  function install_ccontracting() {
    $('#x-cc-FundingSources')
      .bind('axel-update', update_ccontracting)
      .bind('axel-add', recompute_ccontracting)
      .bind('axel-remove', recompute_ccontracting);
  }

  // ********************************************************
  //          Coaching report computed fields
  // ********************************************************

  function update_creport(ev) {
    var hr = $axel('#x-frep-CoachingHourlyRate').peek('CoachingHourlyRate'),
        row = $axel($(ev.target).closest('.x-CoachActivity'));
    row.poke('EffectiveHoursAmount', row.peek('EffectiveNbOfHours') * hr);
    row.poke('ActivityAmount', row.peek('EffectiveOtherExpensesAmount') * 1.0 + row.peek('EffectiveHoursAmount'));
    recompute_creport();
  }

  function recompute_creport() {
    var budget = $axel('#x-frep-Costs'), 
        balance;
    budget.poke('TotalEffectiveHoursNb', budget.vector('EffectiveNbOfHours').sum());
    budget.poke('TotalEffectiveHoursAmount', budget.flush().vector('EffectiveHoursAmount').sum());
    budget.poke('TotalEffectiveOtherExpensesAmount', budget.flush().vector('EffectiveOtherExpensesAmount').sum());
    budget.poke('TotalSpent', budget.flush().vector('ActivityAmount').sum());
    balance =  Math.round((budget.peek('TotalApproved') - budget.peek('TotalSpent'))*100)/100;
    budget.poke('SpentBalance', { '#val' : balance, 'color' : balance >= 0 ? 'green' : 'red' });
  }

  // To be called each time the editor is generated
  function install_creport() {
    $('#x-frep-Costs')
      .bind('axel-update', update_creport)
      .bind('axel-add', recompute_creport)
      .bind('axel-remove', recompute_creport);
    // Manages button to import costs from LogBook - TODO: turn into command
    $('#c-import-costs').bind('click', function (ev) {
      var base = window.location.href.match(/(.*\/\d+).*$/),
          msg = $(ev.target).attr('data-success-msg');
          // TODO: retrieve message from Ajax response
      if (base) {
        base = base[1];
      }
      $axel('#x-frep-Costs').load(base + "/logbook?goal=import");
      if (msg) {
        alert(msg);
      }
      recompute_creport();
    });
  }

  // ********************************************************
  //        Report approval computed fields
  // ********************************************************

  // To be called each time the user changes EffectiveAmount in a FundingSource row
  function update_rapproval(ev) {
    var row = $axel($(ev.target).closest('.x-ra-FundingSource'));
    row.poke('Balance', Math.round(row.peek('ApprovedAmount') * 100 - row.peek('EffectiveAmount') * 100) / 100);
    recompute_rapproval();
  }

  // Recomputes EffectiveBalance and Difference
  function recompute_rapproval() {
    var model = $axel('#x-ra-FinancialStatement'),
        spent_bal = model.peek('SpentBalance'),
        eff_bal = model.vector('Balance').sum(),
        overrun = $axel('#x-ra-FinancialStatement .x-ra-Overrun').peek('EffectiveAmount'),
        balance = Math.round(spent_bal * 100 - eff_bal * 100) / 100 + overrun;
    model.poke('EffectiveBalance', eff_bal);
    model.poke('Difference', { '#val' : balance, 'color' : balance >= 0 ? 'green' : 'red' });
  }

  // To be called each time FinalReportApprovement editor is generated
  function install_rapproval() {
    $('#x-ra-FinancialStatement').bind('axel-update', update_rapproval);
  }

  // ********************************************************
  //        Installation
  // ********************************************************

  function init() {
    // TODO: check if still used ?
    $('.nav-tabs a[data-src]').click(function (e) {
        var jnode = $(this),
            pane= $(jnode.attr('href') + ' div.ajax-res'),
            url = jnode.attr('data-src');
        pane.html('<p id="c-busy" style="height:32px"><span style="margin-left: 48px">Loading in progress...</span></p>');
        jnode.tab('show');
        pane.load(url, function(txt, status, xhr) { if (status !== "success") { pane.html('Impossible to load the page, maybe your session has expired, please reload the page to login again'); } });
    });
    // Temporary c-auto-open: to be integrating in 'accordion' command when AXEL supports untargeted commands
    $('.accordion-group.c-documents.c-auto-open').on('shown', function() { $(this).toggleClass('c-opened') });
    $('.accordion-group.c-documents.c-auto-open').on('hidden', function() { $(this).toggleClass('c-opened') });
    // Coaching plan
    $('#c-editor-coaching-plan').bind('axel-editor-ready', install_cplan);
    $('#c-editor-coaching-plan').bind('axel-content-ready', function () { update_cplan(); });
    // Coach contracting 
    $('#c-editor-coach-contracting').bind('axel-editor-ready', install_ccontracting);
    $('#c-editor-coach-contracting').bind('axel-content-ready', function () {
      $('.x-cc-FundingSource').each(function (i,e) { update_ccontracting({ target: $(e).get(0) }) });
      recompute_ccontracting();
    });
    // Coaching report
    $('#c-editor-coaching-report').bind('axel-editor-ready', install_creport);
    $('#c-editor-coaching-report').bind('axel-content-ready', function () {
      $('.x-CoachActivity').each(function (i,e) { update_creport({ target: $(e).get(0) }) });
      recompute_creport();
    });
    // Report approval
    $('#c-editor-report-approval').bind('axel-editor-ready', install_rapproval);
    $('#c-editor-report-approval').bind('axel-content-ready', function () {
      $('.x-ra-FundingSource').each(function (i,e) { update_rapproval({ target: $(e).get(0) }) });
      recompute_rapproval();
    });
    // Coach match tunnel - NOT AVAILABLE YET
    //$('#c-editor-coaching-assignment').bind('axel-editor-ready', install_coachmatch);
    // Resets content when showing different messages details in modal
    $('#c-alert-details-modal').on('hidden', function() { $(this).removeData(); });
  }

  jQuery(function() { init(); });
}());
