import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/dashboard_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../features/treasury/domain/treasury_model.dart';
import '../../../../shared/widgets/gc_states.dart';

const _green = Color(0xFF087C66);
const _ink = Color(0xFF15211D);

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    return Scaffold(backgroundColor: GoldCraftColors.warmIvory, bottomNavigationBar: const _Nav(), body: SafeArea(child: data.when(
      loading: () => const GcLoadingIndicator(message: 'Preparing workspace...'),
      error: (e, _) => GcErrorState(message: e.toString(), onRetry: () => ref.invalidate(dashboardProvider)),
      data: (s) => RefreshIndicator(color: _green, onRefresh: () async => ref.invalidate(dashboardProvider), child: LayoutBuilder(builder: (context, box) {
        final desktop = box.maxWidth >= 1200;
        final tablet = box.maxWidth >= 700;
        final panels = [_Workshop(s: s), _Overview(s: s, name: user?.name), _Operations(s: s, admin: user?.isAdmin == true)];
        return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: EdgeInsets.all(desktop ? 32 : 18), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: desktop ? IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 4, child: panels[0]), const SizedBox(width: 22), Expanded(flex: 5, child: panels[1]), const SizedBox(width: 22), Expanded(flex: 4, child: panels[2])])) : tablet ? Column(children: [panels[1], const SizedBox(height: 18), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: panels[2]), const SizedBox(width: 18), Expanded(child: panels[0])])]) : Column(children: [panels[1], const SizedBox(height: 18), panels[2], const SizedBox(height: 18), panels[0]]))),
        );
      })),
    )));
  }
}

class _Panel extends StatelessWidget { final Widget child; const _Panel(this.child); @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFFFFEFB), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFECE8DE)), boxShadow: const [BoxShadow(color: Color(0x120E231B), blurRadius: 28, offset: Offset(0,12))]), child: child); }
class _Head extends StatelessWidget { final String title, caption; const _Head(this.title,this.caption); @override Widget build(BuildContext c) => Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(caption,style:const TextStyle(fontSize:10,color:GoldCraftColors.textSecondary)),const SizedBox(height:3),Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:_ink))])),Container(width:36,height:36,decoration:const BoxDecoration(color:Color(0xFFF5F3ED),shape:BoxShape.circle),child:const Icon(Icons.notifications_none_rounded,size:18))]); }

class _Overview extends StatelessWidget { final DashboardSummary s; final String? name; const _Overview({required this.s,this.name}); @override Widget build(BuildContext c) => _Panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_Head('Overview','${DateFormat('EEE, d MMM').format(DateTime.now())} · ${name ?? 'GoldCraft'}'),const SizedBox(height:18),_Gold(t:s.treasury),const SizedBox(height:12),Row(children:[Expanded(child:_Stat('Active jobs','${_active(s)}',Icons.precision_manufacturing_outlined,'/jobs')),const SizedBox(width:12),Expanded(child:_Stat('Payroll queue','${s.pendingPayrollCount}',Icons.payments_outlined,'/payroll'))]),const SizedBox(height:12),_Pulse(s),const SizedBox(height:14),const _Dock()])); }
class _Gold extends StatelessWidget { final TreasurySummary t; const _Gold({required this.t}); @override Widget build(BuildContext c)=>InkWell(onTap:()=>c.push('/treasury'),borderRadius:BorderRadius.circular(22),child:Container(height:190,padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_green,borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Text('Available gold',style:TextStyle(color:Colors.white70,fontSize:11)),const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:Colors.white.withOpacity(.15),borderRadius:BorderRadius.circular(12)),child:const Text('LIVE',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w800)))]),const SizedBox(height:7),Text('${t.availableGoldGrams.toStringAsFixed(3)} g',style:const TextStyle(color:Colors.white,fontSize:31,fontWeight:FontWeight.w800)),const Text('Ready for controlled issue',style:TextStyle(color:Colors.white70,fontSize:11)),const Spacer(),Row(children:[_Fact('In circulation','${t.inCirculationGrams.toStringAsFixed(3)} g'),const SizedBox(width:25),_Fact('Reserve available','${t.reserveRemainingPercent.toStringAsFixed(1)}%')])]))); }
class _Fact extends StatelessWidget { final String a,b; const _Fact(this.a,this.b); @override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:Colors.white54,fontSize:9)),Text(b,style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w700))]); }
class _Stat extends StatelessWidget { final String a,b,r; final IconData i; const _Stat(this.a,this.b,this.i,this.r); @override Widget build(BuildContext c)=>InkWell(onTap:()=>c.push(r),borderRadius:BorderRadius.circular(17),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFF8F7F2),borderRadius:BorderRadius.circular(17),border:Border.all(color:GoldCraftColors.divider)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,size:18,color:_green),const SizedBox(height:9),Text(b,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800,color:_ink)),Text(a,style:const TextStyle(fontSize:10,color:GoldCraftColors.textSecondary))]))); }
class _Pulse extends StatelessWidget { final DashboardSummary s; const _Pulse(this.s); @override Widget build(BuildContext c){final rows=[('Assigned','assigned',const Color(0xFF8CAFA5)),('In progress','inProgress',_green),('Quality check','qualityCheck',GoldCraftColors.jewelryGold),('Completed','completed',GoldCraftColors.softGreenText)]; final max=rows.map((x)=>s.jobsByStatus[x.$2]??0).fold(1,(a,b)=>a>b?a:b); return InkWell(onTap:()=>c.push('/jobs'),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(border:Border.all(color:GoldCraftColors.divider),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Production pulse',style:TextStyle(fontSize:12,fontWeight:FontWeight.w800)),const SizedBox(height:12),for(final x in rows) Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[SizedBox(width:76,child:Text(x.$1,style:const TextStyle(fontSize:10,color:GoldCraftColors.textSecondary))),Expanded(child:LinearProgressIndicator(value:(s.jobsByStatus[x.$2]??0)/max,minHeight:7,color:x.$3,backgroundColor:x.$3.withOpacity(.12))),const SizedBox(width:9),Text('${s.jobsByStatus[x.$2]??0}',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:11))]))])));}}
class _Dock extends StatelessWidget {
  const _Dock();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, 'Overview', '/dashboard'),
      (Icons.scale_outlined, 'Issue', '/material-issuance/new'),
      (Icons.assignment_return_outlined, 'Receive', '/material-receipts/new'),
      (Icons.more_horiz_rounded, 'More', '/reports'),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                onTap: () => context.go(item.$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$1,
                        size: 17,
                        color: item.$2 == 'Overview'
                            ? Colors.white
                            : Colors.white54,
                      ),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 9,
                          color: item.$2 == 'Overview'
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Workshop extends StatelessWidget { final DashboardSummary s; const _Workshop({required this.s}); @override Widget build(BuildContext c)=>_Panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const _Head('Workshop','GoldCraft production floor'),const SizedBox(height:18),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:const Color(0xFFEAF4F0),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.circle,size:9,color:_green),SizedBox(width:8),Text('Live workshop status',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:_green)),Spacer(),Text('Updated now',style:TextStyle(fontSize:10,color:GoldCraftColors.textSecondary))])),const SizedBox(height:14),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:_green,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Active workshop',style:TextStyle(color:Colors.white70,fontSize:10)),Text('${s.totalKaragars} karagars',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:25)),Text('${_active(s)} active jobs · ${s.totalJobs} total ledger',style:const TextStyle(color:Colors.white70,fontSize:10))])),const SizedBox(height:18),const Text('Production queue',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),_Row(Icons.schedule_outlined,s.jobsByStatus['assigned']??0,'Awaiting work start',GoldCraftColors.softBlueText,'/jobs'),_Row(Icons.handyman_outlined,s.jobsByStatus['inProgress']??0,'Currently in production',_green,'/jobs'),_Row(Icons.fact_check_outlined,s.jobsByStatus['qualityCheck']??0,'Waiting for quality check',GoldCraftColors.jewelryGoldDark,'/jobs'),const Spacer(),TextButton.icon(onPressed:()=>c.push('/karagars'),icon:const Icon(Icons.groups_2_outlined),label:const Text('View workshop team'),style:TextButton.styleFrom(foregroundColor:_green))]));}
class _Row extends StatelessWidget {final IconData i;final int n;final String a,r;final Color color;const _Row(this.i,this.n,this.a,this.color,this.r);@override Widget build(BuildContext c)=>InkWell(onTap:()=>c.push(r),child:Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Row(children:[Container(width:32,height:32,decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(10)),child:Icon(i,size:16,color:color)),const SizedBox(width:10),Expanded(child:Text(a,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))),Text('$n',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800))])));}
class _Operations extends StatelessWidget {final DashboardSummary s;final bool admin;const _Operations({required this.s,required this.admin});@override Widget build(BuildContext c){final attention=(s.jobsByStatus['assigned']??0)+(s.jobsByStatus['qualityCheck']??0)+s.pendingPayrollCount;return _Panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const _Head('Operations','Material and finance controls'),const SizedBox(height:18),InkWell(onTap:()=>c.push('/jobs'),child:Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:const Color(0xFFF4EEE2),borderRadius:BorderRadius.circular(20)),child:Row(children:[const CircleAvatar(backgroundColor:GoldCraftColors.jewelryGold,child:Icon(Icons.priority_high,color:Colors.white)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Needs attention',style:TextStyle(fontSize:10,color:GoldCraftColors.textSecondary)),Text('$attention follow-ups',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19)),const Text('Review before next issue cycle',style:TextStyle(fontSize:10,color:GoldCraftColors.textSecondary))])),const Icon(Icons.arrow_forward,color:GoldCraftColors.jewelryGoldDark)]))),const SizedBox(height:12),Row(children:[Expanded(child:_Stat('In circulation','${s.inCirculationGrams.toStringAsFixed(3)} g',Icons.sync_alt_rounded,'/material-issuance')),const SizedBox(width:12),Expanded(child:_Stat('Returned gold','${s.totalGoldReturnedGrams.toStringAsFixed(3)} g',Icons.keyboard_return_rounded,'/treasury'))]),const SizedBox(height:12),_Stat('Outstanding advances','₹${s.outstandingAdvanceRupees.toStringAsFixed(0)}',Icons.account_balance_wallet_outlined,'/advances'),const SizedBox(height:18),const Text('Action queue',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),_Row(Icons.payments_outlined,s.pendingPayrollCount,'Payroll records awaiting action',GoldCraftColors.softRedText,'/payroll'),_Row(Icons.play_circle_outline,s.jobsByStatus['assigned']??0,'Jobs requiring verification',GoldCraftColors.softBlueText,'/jobs'),_Row(Icons.verified_user_outlined,s.jobsByStatus['qualityCheck']??0,'Quality check follow-ups',GoldCraftColors.jewelryGoldDark,'/jobs'),if(admin)...[const Divider(),_Row(Icons.manage_accounts_outlined,0,'Manage team access',_green,'/users'),_Row(Icons.settings_outlined,0,'Workspace settings',GoldCraftColors.textSecondary,'/settings')]]));}}
int _active(DashboardSummary s)=>(s.jobsByStatus['assigned']??0)+(s.jobsByStatus['inProgress']??0)+(s.jobsByStatus['qualityCheck']??0);
class _Nav extends StatelessWidget {
  const _Nav();

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          const routes = ['/dashboard', '/karagars', '/jobs', '/treasury', '/reports'];
          if (index != 0) context.go(routes[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Karagars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined),
            label: 'Treasury',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Reports',
          ),
        ],
      );
}
