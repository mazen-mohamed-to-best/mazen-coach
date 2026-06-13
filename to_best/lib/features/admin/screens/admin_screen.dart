import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.fetchAllUsers();
    if (result?['ok'] == true && result?['users'] != null) {
      final users = (result!['users'] as List<dynamic>)
          .map((u) => UserModel.fromJson(Map<String, dynamic>.from(u)))
          .toList();
      if (mounted) setState(() { _users = users; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserModel> get _filteredUsers {
    if (_search.isEmpty) return _users;
    return _users.where((u) =>
      u.name.toLowerCase().contains(_search.toLowerCase()) ||
      u.email.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(currentUserProvider);

    if (!(me?.isAdminLike ?? false)) {
      return Scaffold(body: Center(child: Text('غير مصرح')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.admin),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'المستخدمون'),
            Tab(text: 'الاشتراكات'),
            Tab(text: 'الأكواد'),
            Tab(text: 'السجل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _UsersTab(
            users: _filteredUsers,
            loading: _loading,
            search: _search,
            me: me,
            onSearch: (v) => setState(() => _search = v),
            onRefresh: _loadUsers,
            onApprove: (uid, approved) => _approveUser(uid, approved),
            onDelete: (uid) => _deleteUser(uid),
            onEdit: (user) => _showEditUser(context, user),
            onForceLogout: (uid) => _forceLogout(uid),
            onChatBan: (uid, ban) => _chatBan(uid, ban),
            l10n: l10n,
            theme: theme,
          ),
          _SubscriptionsTab(l10n: l10n, theme: theme),
          _CodesTab(l10n: l10n, theme: theme),
          _AuditTab(l10n: l10n, theme: theme),
        ],
      ),
    );
  }

  Future<void> _approveUser(String uid, bool approved) async {
    await ApiService.instance.adminApproveUser(uid, approved);
    await _loadUsers();
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: const Text('هل أنت متأكد؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.instance.adminDeleteUser(uid);
      await _loadUsers();
    }
  }

  Future<void> _forceLogout(String uid) async {
    await ApiService.instance.forceLogoutUser(uid);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إجبار المستخدم على الخروج')));
  }

  Future<void> _chatBan(String uid, bool ban) async {
    await ApiService.instance.chatBan(uid, ban);
    await _loadUsers();
  }

  void _showEditUser(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final calCtrl = TextEditingController(text: user.dailyCalories?.toString() ?? '');
    String role = user.role;
    String status = user.status;
    String subType = user.subscriptionType;
    String subStatus = user.subscriptionStatus;
    String program = user.program;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تعديل: ${user.name}', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
                const SizedBox(height: 8),
                TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعرات اليومية')),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: role, isExpanded: true,
                  items: ['SUPER_ADMIN','ADMIN','COACH','TRAINEE','VIEWER'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setInner(() => role = v!),
                ),
                DropdownButton<String>(
                  value: status, isExpanded: true,
                  items: ['active','pending','rejected','inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setInner(() => status = v!),
                ),
                DropdownButton<String>(
                  value: subType, isExpanded: true,
                  items: ['light','full'].map((s) => DropdownMenuItem(value: s, child: Text(s == 'full' ? 'كامل' : 'خفيف'))).toList(),
                  onChanged: (v) => setInner(() => subType = v!),
                ),
                DropdownButton<String>(
                  value: subStatus, isExpanded: true,
                  items: ['none','active','expired','payment_pending'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setInner(() => subStatus = v!),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    await ApiService.instance.adminUpdateUser(user.uid, {
                      'name': nameCtrl.text.trim(),
                      'role': role,
                      'status': status,
                      'subscriptionType': subType,
                      'subscriptionStatus': subStatus,
                      'dailyCalories': double.tryParse(calCtrl.text) ?? user.dailyCalories,
                    });
                    await _loadUsers();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<UserModel> users;
  final bool loading;
  final String search;
  final UserModel? me;
  final Function(String) onSearch;
  final VoidCallback onRefresh;
  final Function(String, bool) onApprove;
  final Function(String) onDelete;
  final Function(UserModel) onEdit;
  final Function(String) onForceLogout;
  final Function(String, bool) onChatBan;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _UsersTab({
    required this.users, required this.loading, required this.search,
    required this.me, required this.onSearch, required this.onRefresh,
    required this.onApprove, required this.onDelete, required this.onEdit,
    required this.onForceLogout, required this.onChatBan,
    required this.l10n, required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'ابحث عن مستخدم…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length,
                itemBuilder: (ctx, i) => _UserCard(
                  user: users[i],
                  me: me,
                  onApprove: onApprove,
                  onDelete: onDelete,
                  onEdit: onEdit,
                  onForceLogout: onForceLogout,
                  onChatBan: onChatBan,
                  l10n: l10n,
                  theme: theme,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final UserModel? me;
  final Function(String, bool) onApprove;
  final Function(String) onDelete;
  final Function(UserModel) onEdit;
  final Function(String) onForceLogout;
  final Function(String, bool) onChatBan;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _UserCard({
    required this.user, required this.me, required this.onApprove,
    required this.onDelete, required this.onEdit, required this.onForceLogout,
    required this.onChatBan, required this.l10n, required this.theme,
  });

  Color _roleColor(String r) {
    switch (r.toUpperCase()) {
      case 'SUPER_ADMIN': return AppColors.superAdminColor;
      case 'ADMIN': return AppColors.adminColor;
      case 'COACH': return AppColors.coachColor;
      default: return AppColors.traineeColor;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'rejected': return AppColors.error;
      default: return AppColors.darkSubText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _roleColor(user.role).withOpacity(0.2),
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(color: _roleColor(user.role), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleSmall),
                      Text(user.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _statusColor(user.status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(user.status, style: TextStyle(color: _statusColor(user.status), fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Badge(user.role, _roleColor(user.role)),
                const SizedBox(width: 6),
                _Badge(user.program, theme.colorScheme.primary),
                const SizedBox(width: 6),
                _Badge(user.subscriptionStatus, user.isSubscriptionActive ? AppColors.success : AppColors.error),
              ],
            ),
            if (user.status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => onApprove(user.uid, true),
                    icon: const Icon(Icons.check, size: 14),
                    label: Text(l10n.approveUser, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => onApprove(user.uid, false),
                    icon: const Icon(Icons.close, size: 14),
                    label: Text(l10n.rejectUser, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  )),
                ],
              ),
            ],
            const SizedBox(height: 6),
            if (me?.uid != user.uid)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(onPressed: () => onEdit(user), icon: const Icon(Icons.edit, size: 14), label: const Text('تعديل', style: TextStyle(fontSize: 12))),
                  TextButton.icon(onPressed: () => onForceLogout(user.uid), icon: const Icon(Icons.logout, size: 14), label: const Text('إخراج', style: TextStyle(fontSize: 12))),
                  TextButton.icon(
                    onPressed: () => onDelete(user.uid),
                    icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                    label: const Text('حذف', style: TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _SubscriptionsTab extends StatefulWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  const _SubscriptionsTab({required this.l10n, required this.theme});
  @override
  State<_SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<_SubscriptionsTab> {
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getSubscriptionRequests();
    if (mounted) {
      setState(() {
        _requests = (result?['requests'] as List<dynamic>?) ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_requests.isEmpty) return Center(child: Text('لا توجد طلبات اشتراك', style: widget.theme.textTheme.bodyMedium));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (ctx, i) {
          final req = _requests[i] as Map<String, dynamic>;
          final status = req['status']?.toString() ?? 'pending';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(req['name']?.toString() ?? 'Unknown', style: widget.theme.textTheme.titleSmall)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'pending' ? Colors.orange.withOpacity(0.2) : status == 'approved' ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status, style: TextStyle(fontSize: 11, color: status == 'pending' ? Colors.orange : status == 'approved' ? AppColors.success : AppColors.error)),
                    ),
                  ]),
                  Text('${req['subscriptionType']} • ${req['subscriptionDuration']} شهر', style: widget.theme.textTheme.bodySmall),
                  Text('${req['amount']} — ${req['createdAt']}', style: widget.theme.textTheme.labelSmall),
                  if (req['imageUrl'] != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(onPressed: () {}, icon: const Icon(Icons.image, size: 14), label: const Text('عرض الإيصال')),
                  ],
                  if (status == 'pending') ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: ElevatedButton(
                        onPressed: () async {
                          await ApiService.instance.updateSubscriptionRequest(req['id'].toString(), 'approved', null);
                          _load();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        child: const Text('موافقة', style: TextStyle(color: Colors.white, fontSize: 12)),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(
                        onPressed: () async {
                          await ApiService.instance.updateSubscriptionRequest(req['id'].toString(), 'rejected', null);
                          _load();
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                        child: const Text('رفض', style: TextStyle(fontSize: 12)),
                      )),
                    ]),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CodesTab extends StatefulWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  const _CodesTab({required this.l10n, required this.theme});
  @override
  State<_CodesTab> createState() => _CodesTabState();
}

class _CodesTabState extends State<_CodesTab> with SingleTickerProviderStateMixin {
  late TabController _sub;
  List<dynamic> _promos = [];
  List<dynamic> _guests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _sub.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await ApiService.instance.listPromos();
    final g = await ApiService.instance.listGuestCodes();
    if (mounted) setState(() {
      _promos = (p?['promos'] as List?) ?? [];
      _guests = (g?['codes'] as List?) ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(controller: _sub, tabs: const [Tab(text: 'أكواد الخصم'), Tab(text: 'أكواد الضيف')]),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
        else Expanded(
          child: TabBarView(controller: _sub, children: [
            _PromoList(promos: _promos, theme: widget.theme, onDelete: (code) async {
              await ApiService.instance.deletePromo(code);
              _load();
            }, onCreate: () => _showCreatePromo(context)),
            _GuestList(guests: _guests, theme: widget.theme, onDelete: (code) async {
              await ApiService.instance.deleteGuestCode(code);
              _load();
            }, onCreate: () async { await ApiService.instance.createGuestCode(); _load(); }),
          ]),
        ),
      ],
    );
  }

  void _showCreatePromo(BuildContext context) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final usesCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('كود خصم جديد'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'الكود')),
          TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نسبة الخصم %')),
          TextField(controller: usesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الحد الأقصى للاستخدام')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await ApiService.instance.createPromo(codeCtrl.text.trim(), double.tryParse(discountCtrl.text) ?? 0, int.tryParse(usesCtrl.text) ?? 10);
              _load();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }
}

class _PromoList extends StatelessWidget {
  final List<dynamic> promos;
  final ThemeData theme;
  final Function(String) onDelete;
  final VoidCallback onCreate;
  const _PromoList({required this.promos, required this.theme, required this.onDelete, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('كود خصم جديد'))),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: promos.map((p) {
          final m = p as Map<String, dynamic>;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: const Text('🏷️', style: TextStyle(fontSize: 22)),
            title: Text(m['code']?.toString() ?? '', style: theme.textTheme.titleSmall),
            subtitle: Text('${m['discount']}% خصم • ${m['uses']}/${m['maxUses']} استخدام'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => onDelete(m['code'].toString())),
          ));
        }).toList())),
      ],
    );
  }
}

class _GuestList extends StatelessWidget {
  final List<dynamic> guests;
  final ThemeData theme;
  final Function(String) onDelete;
  final VoidCallback onCreate;
  const _GuestList({required this.guests, required this.theme, required this.onDelete, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('كود ضيف جديد'))),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: guests.map((g) {
          final m = g as Map<String, dynamic>;
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: const Text('👤', style: TextStyle(fontSize: 22)),
            title: Text(m['code']?.toString() ?? '', style: theme.textTheme.titleSmall),
            subtitle: Text(m['used'] == true ? 'مستخدم' : 'متاح'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => onDelete(m['code'].toString())),
          ));
        }).toList())),
      ],
    );
  }
}

class _AuditTab extends StatefulWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  const _AuditTab({required this.l10n, required this.theme});
  @override
  State<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<_AuditTab> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAuditLog();
    if (mounted) setState(() {
      _logs = (result?['logs'] as List?) ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_logs.isEmpty) return Center(child: Text('لا يوجد سجل', style: widget.theme.textTheme.bodyMedium));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      itemBuilder: (ctx, i) {
        final log = _logs[i] as Map<String, dynamic>;
        return Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
          dense: true,
          leading: const Icon(Icons.history, size: 18),
          title: Text(log['action']?.toString() ?? '', style: widget.theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text('${log['by']} • ${log['ts']}', style: widget.theme.textTheme.labelSmall),
          trailing: log['uid'] != null ? Text(log['uid'].toString().substring(0, 6), style: widget.theme.textTheme.labelSmall) : null,
        ));
      },
    );
  }
}
