import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/views/admin/admin_shop/add_products.dart';
import 'package:online_barber_app/views/admin/admin_shop/edit_product.dart';

class AllProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Products'),
        actions: [
          IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProducts(),
              ),
            );
          }, icon: Icon(Icons.add))
        ],


      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data?.docs;

          return ListView.builder(
            itemCount: products?.length ?? 0,
            itemBuilder: (context, index) {
              final product = products![index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              return ListTile(
                leading: Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                title: Text('Price: ${product['price']}'),
                subtitle: Text(product['description']),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProductPage(productId: productId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
