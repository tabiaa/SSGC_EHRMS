import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/dependent.dart';
import '../services/api_service.dart';
import '../widgets/dependent_detail_form.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class DependentsScreen extends StatefulWidget {
  const DependentsScreen({Key? key}) : super(key: key); 

  @override
  _DependentsScreenState createState() => _DependentsScreenState();
}

class _DependentsScreenState extends State<DependentsScreen> {
  List<Dependent>? _dependents;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDependents();
  }

  Future<void> _loadDependents() async {
    try {
      final deps = await ApiService.getDependents();

      if (mounted) {
        setState(() {
         
          deps.sort((a, b) {
            if (a.relationshipType.toLowerCase() == 'self') return -1;
            if (b.relationshipType.toLowerCase() == 'self') return 1;
            return 0;
          });

          _dependents = deps;
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _loading = false);

      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        Provider.of<AuthService>(context, listen: false).logout();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) =>  LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      String errorMsg = 'Failed to load dependents';
      if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'No internet connection.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMsg = 'Server error. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error occurred.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    const Color ssgcOrange = Color(0xFFEA7600);
    const Color softBackground = Color(0xFFF8F8F8);

    final employee = auth.user;
    final fullName = employee ?? 'Employee';

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: ssgcOrange,
        elevation: 2,
        title: const Text(
          'Medical Dependents',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) =>  LoginScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ssgcOrange))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ssgcOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ssgcOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined, color: ssgcOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF5A3B00),
                                ),
                              ),
                              // Text(
                              //   employee,
                              //   style: TextStyle(
                              //     fontSize: 13,
                              //     color: ssgcOrange.withOpacity(0.9),
                              //     fontWeight: FontWeight.w500,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ssgcOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ssgcOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFFEA7600)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dependents listed here are eligible for SSGC medical benefits.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB85C00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _dependents == null || _dependents!.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: ssgcOrange,
                          onRefresh: _loadDependents,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _dependents!.length,
                            itemBuilder: (context, index) {
                              final dep = _dependents![index];
                              return _buildDependentCard(dep);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    const Color ssgcOrange = Color(0xFFEA7600);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom_outlined,
                size: 90, color: ssgcOrange.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text(
              'No dependents found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEA7600),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No dependents listed',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependentCard(Dependent dep) {
    const Color ssgcOrange = Color(0xFFEA7600);
    const Color selfGreen = Color(0xFF2E7D32); 

    final bool isSelf = dep.relationshipType.toLowerCase() == 'self';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DependentDetailForm(
                dependent: dep,
                onUpdated: _loadDependents,
              ),
            ),
          );
          _loadDependents();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelf
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [const Color(0xFFFFFFFF), const Color(0xFFFFF4E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelf
                  ? selfGreen.withOpacity(0.4)
                  : ssgcOrange.withOpacity(0.15),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isSelf
                    ? selfGreen.withOpacity(0.15)
                    : ssgcOrange.withOpacity(0.15),
                backgroundImage: dep.profilePictureUrl?.isNotEmpty == true
                    ? NetworkImage(dep.profilePictureUrl!)
                    : null,
                child: dep.profilePictureUrl?.isNotEmpty == true
                    ? null
                    : Icon(
                        Icons.person,
                        color: isSelf ? selfGreen : ssgcOrange,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dep.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5A3B00),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dep.relationshipType,
                      style: TextStyle(
                        color: isSelf
                            ? selfGreen.withOpacity(0.9)
                            : ssgcOrange.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isSelf ? selfGreen : ssgcOrange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}