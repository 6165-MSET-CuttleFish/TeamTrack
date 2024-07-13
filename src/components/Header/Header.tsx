tsx
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Image } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '@react-navigation/native';
import { useSelector } from 'react-redux';
import { RootState } from '../../redux/store';

const Header = () => {
  const navigation = useNavigation();
  const theme = useTheme();
  const user = useSelector((state: RootState) => state.auth.user);

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.primary }]} >
      <View style={styles.content}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Image source={require('../../assets/images/backArrow.png')} style={styles.backArrow} />
        </TouchableOpacity>
        <Text style={styles.title}>
          {user?.displayName ?? "TeamTrack"}
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: 60,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 10,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-start',
    width: '100%',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
    marginLeft: 10,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  backArrow: {
    width: 20,
    height: 20,
  },
});

export default Header;